#!/bin/bash

# This generates big query denormalized tables for search.

set -xeuo pipefail
IFS=$'\n\t'


# get options

# --cdr=cdr_version ... *optional
USAGE="./generate-clousql-cdr/make-bq-denormalized-search.sh --bq-project <PROJECT> --bq-dataset <DATASET>"

while [ $# -gt 0 ]; do
  echo "1 is $1"
  case "$1" in
    --bq-project) BQ_PROJECT=$2; shift 2;;
    --bq-dataset) BQ_DATASET=$2; shift 2;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done


if [ -z "${BQ_PROJECT}" ]
then
  echo "Usage: $USAGE"
  exit 1
fi

if [ -z "${BQ_DATASET}" ]
then
  echo "Usage: $USAGE"
  exit 1
fi


# Check that bq_dataset exists and exit if not
datasets=$(bq --project=$BQ_PROJECT ls)
if [ -z "$datasets" ]
then
  echo "$BQ_PROJECT.$BQ_DATASET does not exist. Please specify a valid project and dataset."
  exit 1
fi
if [[ $datasets =~ .*$BQ_DATASET.* ]]; then
  echo "$BQ_PROJECT.$BQ_DATASET exists. Good. Carrying on."
else
  echo "$BQ_PROJECT.$BQ_DATASET does not exist. Please specify a valid project and dataset."
  exit 1
fi

# Create bq tables we have json schema for
schema_path=generate-cdr/bq-schemas

bq --project=$BQ_PROJECT rm -f $BQ_DATASET.search_person
bq --quiet --project=$BQ_PROJECT mk --schema=$schema_path/search_person.json --time_partitioning_type=DAY --clustering_fields person_id $BQ_DATASET.search_person

bq --project=$BQ_PROJECT rm -f $BQ_DATASET.search_codes
bq --quiet --project=$BQ_PROJECT mk --schema=$schema_path/search_codes.json --time_partitioning_type=DAY --clustering_fields concept_id_or_source_concept_id $BQ_DATASET.search_codes

create_concept_tables=(search_drug search_measurement search_visit)
for t in "${create_concept_tables[@]}"
do
    bq --project=$BQ_PROJECT rm -f $BQ_DATASET.$t
    bq --quiet --project=$BQ_PROJECT mk --schema=$schema_path/$t.json --time_partitioning_type=DAY --clustering_fields concept_id $BQ_DATASET.$t
done

create_source_concept_tables=(search_ppi search_pm)
for t in "${create_source_concept_tables[@]}"
do
    bq --project=$BQ_PROJECT rm -f $BQ_DATASET.$t
    bq --quiet --project=$BQ_PROJECT mk --schema=$schema_path/$t.json --time_partitioning_type=DAY --clustering_fields source_concept_id $BQ_DATASET.$t
done

# Populate some tables from cdr data

################################################
#   insert condition data into search_person   #
################################################
echo "Inserting conditions data into search_person"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.search_person\`
 (person_id, gender, race, dob)
select p.person_id, g.concept_code as gender,
case when r.concept_name is null then 'Unknown' else r.concept_name end as race,
birth_datetime as dob
from \`$BQ_PROJECT.$BQ_DATASET.person\` p
join \`$BQ_PROJECT.$BQ_DATASET.concept\` g on (p.gender_concept_id = g.concept_id and g.vocabulary_id in ('Gender', 'None'))
left join \`$BQ_PROJECT.$BQ_DATASET.concept\` r on (p.race_concept_id = r.concept_id and r.vocabulary_id = 'Race')"

##########################################################
#   insert condition data into search_codes from ICD9    #
##########################################################
echo "Inserting conditions data into search_codes"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.search_codes\`
 (person_id, entry_date, concept_id_or_source_concept_id, type, subtype, age_at_event, visit_concept_id)
select co.person_id, co.condition_start_date as entry_date, co.condition_source_concept_id as source_concept_id, c.type, c.subtype,
cast(floor(date_diff(co.condition_start_date, date(p.year_of_birth, p.month_of_birth, p.day_of_birth), month)/12) as int64) as age_at_event,
vo.visit_concept_id
from \`$BQ_PROJECT.$BQ_DATASET.condition_occurrence\` co
join \`$BQ_PROJECT.$BQ_DATASET.criteria\` c on (c.concept_id = co.condition_source_concept_id and c.is_selectable = 1 and c.type = 'ICD9')
join \`$BQ_PROJECT.$BQ_DATASET.person\` p on (p.person_id = co.person_id)
left join \`$BQ_PROJECT.$BQ_DATASET.visit_occurrence\` vo on (vo.visit_occurrence_id = co.visit_occurrence_id)"

echo "Inserting procedures data into search_codes"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.search_codes\`
 (person_id, entry_date, concept_id_or_source_concept_id, type, subtype, age_at_event, visit_concept_id)
select po.person_id, po.procedure_date as entry_date, po.procedure_source_concept_id as source_concept_id, c.type, c.subtype,
cast(floor(date_diff(po.procedure_date, date(p.year_of_birth, p.month_of_birth, p.day_of_birth), month)/12) as int64) as age_at_event,
vo.visit_concept_id
from \`$BQ_PROJECT.$BQ_DATASET.procedure_occurrence\` po
join \`$BQ_PROJECT.$BQ_DATASET.criteria\` c on (c.concept_id = po.procedure_source_concept_id and c.is_selectable = 1 and c.type = 'ICD9')
join \`$BQ_PROJECT.$BQ_DATASET.person\` p on (p.person_id = po.person_id)
left join \`$BQ_PROJECT.$BQ_DATASET.visit_occurrence\` vo on (vo.visit_occurrence_id = po.visit_occurrence_id)"

echo "Inserting measurements data into search_codes"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.search_codes\`
 (person_id, entry_date, concept_id_or_source_concept_id, type, subtype, age_at_event, visit_concept_id)
select m.person_id, m.measurement_date as entry_date, m.measurement_source_concept_id as source_concept_id, c.type, c.subtype,
cast(floor(date_diff(m.measurement_date, date(p.year_of_birth, p.month_of_birth, p.day_of_birth), month)/12) as int64) as age_at_event,
vo.visit_concept_id
from \`$BQ_PROJECT.$BQ_DATASET.measurement\` m
join \`$BQ_PROJECT.$BQ_DATASET.criteria\` c on (c.concept_id = m.measurement_source_concept_id and c.is_selectable = 1 and c.type = 'ICD9')
join \`$BQ_PROJECT.$BQ_DATASET.person\` p on (p.person_id = m.person_id)
left join \`$BQ_PROJECT.$BQ_DATASET.visit_occurrence\` vo on (vo.visit_occurrence_id = m.visit_occurrence_id)"

echo "Inserting observations data into search_codes"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.search_codes\`
 (person_id, entry_date, concept_id_or_source_concept_id, type, subtype, age_at_event, visit_concept_id)
select o.person_id, o.observation_date as entry_date, o.observation_source_concept_id as source_concept_id, c.type, c.subtype,
cast(floor(date_diff(o.observation_date, date(p.year_of_birth, p.month_of_birth, p.day_of_birth), month)/12) as int64) as age_at_event,
vo.visit_concept_id
from \`$BQ_PROJECT.$BQ_DATASET.observation\` o
join \`$BQ_PROJECT.$BQ_DATASET.criteria\` c on (c.concept_id = o.observation_source_concept_id and c.is_selectable = 1 and c.type = 'ICD9')
join \`$BQ_PROJECT.$BQ_DATASET.person\` p on (p.person_id = o.person_id)
left join \`$BQ_PROJECT.$BQ_DATASET.visit_occurrence\` vo on (vo.visit_occurrence_id = o.visit_occurrence_id)"

#########################################################
#   insert condition data into search_codes for ICD10   #
#########################################################
echo "Inserting conditions data into search_codes"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.search_codes\`
 (person_id, entry_date, concept_id_or_source_concept_id, type, subtype, age_at_event, visit_concept_id)
select co.person_id, co.condition_start_date as entry_date, co.condition_source_concept_id as source_concept_id, c.type, c.subtype,
cast(floor(date_diff(co.condition_start_date, date(p.year_of_birth, p.month_of_birth, p.day_of_birth), month)/12) as int64) as age_at_event,
vo.visit_concept_id
from \`$BQ_PROJECT.$BQ_DATASET.condition_occurrence\` co
join \`$BQ_PROJECT.$BQ_DATASET.criteria\` c on (c.concept_id = co.condition_source_concept_id and c.is_selectable = 1 and c.type = 'ICD10')
join \`$BQ_PROJECT.$BQ_DATASET.person\` p on (p.person_id = co.person_id)
left join \`$BQ_PROJECT.$BQ_DATASET.visit_occurrence\` vo on (vo.visit_occurrence_id = co.visit_occurrence_id)"

echo "Inserting procedures data into search_codes"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.search_codes\`
 (person_id, entry_date, concept_id_or_source_concept_id, type, subtype, age_at_event, visit_concept_id)
select po.person_id, po.procedure_date as entry_date, po.procedure_source_concept_id as source_concept_id, c.type, c.subtype,
cast(floor(date_diff(po.procedure_date, date(p.year_of_birth, p.month_of_birth, p.day_of_birth), month)/12) as int64) as age_at_event,
vo.visit_concept_id
from \`$BQ_PROJECT.$BQ_DATASET.procedure_occurrence\` po
join \`$BQ_PROJECT.$BQ_DATASET.criteria\` c on (c.concept_id = po.procedure_source_concept_id and c.is_selectable = 1 and c.type = 'ICD10')
join \`$BQ_PROJECT.$BQ_DATASET.person\` p on (p.person_id = po.person_id)
left join \`$BQ_PROJECT.$BQ_DATASET.visit_occurrence\` vo on (vo.visit_occurrence_id = po.visit_occurrence_id)"

echo "Inserting observations data into search_codes"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.search_codes\`
 (person_id, entry_date, concept_id_or_source_concept_id, type, subtype, age_at_event, visit_concept_id)
select o.person_id, o.observation_date as entry_date, o.observation_source_concept_id as source_concept_id, c.type, c.subtype,
cast(floor(date_diff(o.observation_date, date(p.year_of_birth, p.month_of_birth, p.day_of_birth), month)/12) as int64) as age_at_event,
vo.visit_concept_id
from \`$BQ_PROJECT.$BQ_DATASET.observation\` o
join \`$BQ_PROJECT.$BQ_DATASET.criteria\` c on (c.concept_id = o.observation_source_concept_id and c.is_selectable = 1 and c.type = 'ICD10')
join \`$BQ_PROJECT.$BQ_DATASET.person\` p on (p.person_id = o.person_id)
left join \`$BQ_PROJECT.$BQ_DATASET.visit_occurrence\` vo on (vo.visit_occurrence_id = o.visit_occurrence_id)"

#######################################################
#   insert condition data into search_codes for CPT   #
#######################################################
echo "Inserting drug data into search_codes"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.search_codes\`
 (person_id, entry_date, concept_id_or_source_concept_id, type, subtype, age_at_event, visit_concept_id)
select de.person_id, de.drug_exposure_start_date as entry_date, de.drug_source_concept_id as source_concept_id, c.type, c.subtype,
cast(floor(date_diff(de.drug_exposure_start_date, date(p.year_of_birth, p.month_of_birth, p.day_of_birth), month)/12) as int64) as age_at_event,
vo.visit_concept_id
from \`$BQ_PROJECT.$BQ_DATASET.drug_exposure\` de
join \`$BQ_PROJECT.$BQ_DATASET.criteria\` c on (c.concept_id = de.drug_source_concept_id and c.is_selectable = 1 and c.type = 'CPT')
join \`$BQ_PROJECT.$BQ_DATASET.person\` p on (p.person_id = de.person_id)
left join \`$BQ_PROJECT.$BQ_DATASET.visit_occurrence\` vo on (vo.visit_occurrence_id = de.visit_occurrence_id)"

echo "Inserting procedures data into search_codes"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.search_codes\`
 (person_id, entry_date, concept_id_or_source_concept_id, type, subtype, age_at_event, visit_concept_id)
select po.person_id, po.procedure_date as entry_date, po.procedure_source_concept_id as source_concept_id, c.type, c.subtype,
cast(floor(date_diff(po.procedure_date, date(p.year_of_birth, p.month_of_birth, p.day_of_birth), month)/12) as int64) as age_at_event,
vo.visit_concept_id
from \`$BQ_PROJECT.$BQ_DATASET.procedure_occurrence\` po
join \`$BQ_PROJECT.$BQ_DATASET.criteria\` c on (c.concept_id = po.procedure_source_concept_id and c.is_selectable = 1 and c.type = 'CPT')
join \`$BQ_PROJECT.$BQ_DATASET.person\` p on (p.person_id = po.person_id)
left join \`$BQ_PROJECT.$BQ_DATASET.visit_occurrence\` vo on (vo.visit_occurrence_id = po.visit_occurrence_id)"

echo "Inserting measurements data into search_codes"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.search_codes\`
 (person_id, entry_date, concept_id_or_source_concept_id, type, subtype, age_at_event, visit_concept_id)
select m.person_id, m.measurement_date as entry_date, m.measurement_source_concept_id as source_concept_id, c.type, c.subtype,
cast(floor(date_diff(m.measurement_date, date(p.year_of_birth, p.month_of_birth, p.day_of_birth), month)/12) as int64) as age_at_event,
vo.visit_concept_id
from \`$BQ_PROJECT.$BQ_DATASET.measurement\` m
join \`$BQ_PROJECT.$BQ_DATASET.criteria\` c on (c.concept_id = m.measurement_source_concept_id and c.is_selectable = 1 and c.type = 'CPT')
join \`$BQ_PROJECT.$BQ_DATASET.person\` p on (p.person_id = m.person_id)
left join \`$BQ_PROJECT.$BQ_DATASET.visit_occurrence\` vo on (vo.visit_occurrence_id = m.visit_occurrence_id)"

echo "Inserting observations data into search_codes"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.search_codes\`
 (person_id, entry_date, concept_id_or_source_concept_id, type, subtype, age_at_event, visit_concept_id)
select o.person_id, o.observation_date as entry_date, o.observation_source_concept_id as source_concept_id, c.type, c.subtype,
cast(floor(date_diff(o.observation_date, date(p.year_of_birth, p.month_of_birth, p.day_of_birth), month)/12) as int64) as age_at_event,
vo.visit_concept_id
from \`$BQ_PROJECT.$BQ_DATASET.observation\` o
join \`$BQ_PROJECT.$BQ_DATASET.criteria\` c on (c.concept_id = o.observation_source_concept_id and c.is_selectable = 1 and c.type = 'CPT')
join \`$BQ_PROJECT.$BQ_DATASET.person\` p on (p.person_id = o.person_id)
left join \`$BQ_PROJECT.$BQ_DATASET.visit_occurrence\` vo on (vo.visit_occurrence_id = o.visit_occurrence_id)"

##########################################################
#   insert condition data into search_codes for SNOMED   #
##########################################################
echo "Inserting conditions data into search_codes"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.search_codes\`
 (person_id, entry_date, concept_id_or_source_concept_id, type, subtype, age_at_event, visit_concept_id)
select co.person_id, co.condition_start_date as entry_date, co.condition_concept_id as concept_id, c.type, c.subtype,
cast(floor(date_diff(co.condition_start_date, date(p.year_of_birth, p.month_of_birth, p.day_of_birth), month)/12) as int64) as age_at_event,
vo.visit_concept_id
from \`$BQ_PROJECT.$BQ_DATASET.condition_occurrence\` co
join (select distinct concept_id, is_selectable, type, subtype from \`$BQ_PROJECT.$BQ_DATASET.criteria\`
where is_selectable = 1
and type = 'SNOMED'
and subtype = 'CM') c on (c.concept_id = co.condition_concept_id)
join \`$BQ_PROJECT.$BQ_DATASET.person\` p on (p.person_id = co.person_id)
left join \`$BQ_PROJECT.$BQ_DATASET.visit_occurrence\` vo on (vo.visit_occurrence_id = co.visit_occurrence_id)"

echo "Inserting procedures data into search_codes"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.search_codes\`
 (person_id, entry_date, concept_id_or_source_concept_id, type, subtype, age_at_event, visit_concept_id)
select po.person_id, po.procedure_date as entry_date, po.procedure_concept_id as concept_id, c.type, c.subtype,
cast(floor(date_diff(po.procedure_date, date(p.year_of_birth, p.month_of_birth, p.day_of_birth), month)/12) as int64) as age_at_event,
vo.visit_concept_id
from \`$BQ_PROJECT.$BQ_DATASET.procedure_occurrence\` po
join (select distinct concept_id, is_selectable, type, subtype from \`$BQ_PROJECT.$BQ_DATASET.criteria\`
where is_selectable = 1
and type = 'SNOMED'
and subtype = 'PCS') c on (c.concept_id = po.procedure_concept_id)
join \`$BQ_PROJECT.$BQ_DATASET.person\` p on (p.person_id = po.person_id)
left join \`$BQ_PROJECT.$BQ_DATASET.visit_occurrence\` vo on (vo.visit_occurrence_id = po.visit_occurrence_id)"

################################################
#   insert condition data into search_drug     #
################################################
echo "Inserting conditions data into search_drug"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.search_drug\`
 (person_id, entry_date, concept_id, subtype, age_at_event, visit_concept_id)
select de.person_id, de.drug_exposure_start_date as entry_date, de.drug_concept_id as concept_id, c.subtype,
cast(floor(date_diff(de.drug_exposure_start_date, date(p.year_of_birth, p.month_of_birth, p.day_of_birth), month)/12) as int64) as age_at_event,
vo.visit_concept_id
from \`$BQ_PROJECT.$BQ_DATASET.drug_exposure\` de
join (select distinct concept_id, is_selectable, type, subtype from \`$BQ_PROJECT.$BQ_DATASET.criteria\`
where is_selectable = 1
and type = 'DRUG'
and subtype = 'ATC') c on (c.concept_id = de.drug_concept_id)
join \`$BQ_PROJECT.$BQ_DATASET.person\` p on (p.person_id = de.person_id)
left join \`$BQ_PROJECT.$BQ_DATASET.visit_occurrence\` vo on (vo.visit_occurrence_id = de.visit_occurrence_id)"

#####################################################
#   insert condition data into search_measurement   #
#####################################################
echo "Inserting conditions data into search_measurement"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.search_measurement\`
 (person_id, entry_date, concept_id, subtype, age_at_event, visit_concept_id, value_as_number, value_as_concept_id)
select m.person_id, m.measurement_date as entry_date, m.measurement_concept_id as concept_id, c.subtype,
cast(floor(date_diff(m.measurement_date, date(p.year_of_birth, p.month_of_birth, p.day_of_birth), month)/12) as int64) as age_at_event,
vo.visit_concept_id, m.value_as_number, m.value_as_concept_id
from \`$BQ_PROJECT.$BQ_DATASET.measurement\` m
join (select distinct concept_id, is_selectable, type, subtype from \`$BQ_PROJECT.$BQ_DATASET.criteria\`
where is_selectable = 1
and type = 'MEAS') c on (c.concept_id = m.measurement_concept_id)
join \`$BQ_PROJECT.$BQ_DATASET.person\` p on (p.person_id = m.person_id)
left join \`$BQ_PROJECT.$BQ_DATASET.visit_occurrence\` vo on (vo.visit_occurrence_id = m.visit_occurrence_id)"

#####################################################
#   insert condition data into search_visit   #
#####################################################
echo "Inserting conditions data into search_visit"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.search_visit\`
 (person_id, entry_date, concept_id, age_at_event, visit_concept_id)
select vo.person_id, vo.visit_start_date as entry_date, vo.visit_concept_id as concept_id,
cast(floor(date_diff(vo.visit_start_date, date(p.year_of_birth, p.month_of_birth, p.day_of_birth), month)/12) as int64) as age_at_event,
vo.visit_concept_id
from \`$BQ_PROJECT.$BQ_DATASET.visit_occurrence\` vo
join \`$BQ_PROJECT.$BQ_DATASET.criteria\` c on (c.concept_id = vo.visit_concept_id and c.is_selectable = 1 and c.type = 'VISIT')
join \`$BQ_PROJECT.$BQ_DATASET.person\` p on (p.person_id = vo.person_id)"

#####################################################
#   insert condition data into search_ppi   #
#####################################################
echo "Inserting conditions data into search_ppi"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.search_ppi\`
 (person_id, entry_date, source_concept_id, subtype, value_as_number, value_as_concept_id)
select o.person_id, o.observation_date as entry_date, o.observation_source_concept_id as source_concept_id,
c.subtype, o.value_as_number, o.value_as_concept_id
from \`$BQ_PROJECT.$BQ_DATASET.observation\` o
join (select distinct concept_id, is_selectable, type, subtype from \`$BQ_PROJECT.$BQ_DATASET.criteria\`
where is_selectable = 1
and type = 'PPI') c on (c.concept_id = o.observation_source_concept_id)
join \`$BQ_PROJECT.$BQ_DATASET.person\` p on (p.person_id = o.person_id)"

############################################
#   insert condition data into search_pm   #
############################################
echo "Inserting conditions data into search_pm"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.search_pm\`
 (person_id, entry_date, source_concept_id, subtype, value_as_number, value_as_concept_id)
select m.person_id, m.measurement_date as entry_date, m.measurement_source_concept_id as source_concept_id,
c.subtype, m.value_as_number, m.value_as_concept_id
from \`$BQ_PROJECT.$BQ_DATASET.measurement\` m
join (select distinct concept_id, is_selectable, type, subtype from \`$BQ_PROJECT.$BQ_DATASET.criteria\`
where is_selectable = 1
and type = 'PM') c on (c.concept_id = m.measurement_source_concept_id)
join \`$BQ_PROJECT.$BQ_DATASET.person\` p on (p.person_id = m.person_id)"

echo "Inserting conditions data into search_pm"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.search_pm\`
 (person_id, entry_date, source_concept_id, subtype, value_as_number, value_as_concept_id)
select m.person_id, m.measurement_date as entry_date, m.measurement_source_concept_id as source_concept_id,
'BP', m.value_as_number, m.value_as_concept_id
from \`$BQ_PROJECT.$BQ_DATASET.measurement\` m
join \`$BQ_PROJECT.$BQ_DATASET.person\` p on (p.person_id = m.person_id)
where m.measurement_source_concept_id in (903118, 903115)"