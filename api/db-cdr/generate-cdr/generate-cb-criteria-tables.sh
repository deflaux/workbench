#!/bin/bash

# This generates the criteria tables for the CDR

# PREP: upload all prep tables

# Example usage:
# ./project.rb generate-cb-criteria-tables --bq-project aou-res-curation-prod --bq-dataset deid_output_20181116
# ./project.rb generate-cb-criteria-tables --bq-project all-of-us-ehr-dev --bq-dataset synthetic_cdr20180606


set -xeuo pipefail
IFS=$'\n\t'

# --cdr=cdr_version ... *optional
USAGE="./generate-cdr/generate-cb-criteria-tables.sh --bq-project <PROJECT> --bq-dataset <DATASET>"

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

# Check that bq_project exists and exit if not
datasets=$(bq --project=$BQ_PROJECT ls --max_results=150)
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

# Check that bq_dataset exists and exit if not
datasets=$(bq --project=$BQ_PROJECT ls --max_results=150)
if [ -z "$datasets" ]
then
  echo "$BQ_PROJECT.$BQ_DATASET does not exist. Please specify a valid project and dataset."
  exit 1
fi
re=\\b$BQ_DATASET\\b
if [[ $datasets =~ $re ]]; then
  echo "$BQ_PROJECT.$BQ_DATASET exists. Good. Carrying on."
else
  echo "$BQ_PROJECT.$BQ_DATASET does not exist. Please specify a valid project and dataset."
  exit 1
fi


################################################
# CREATE TABLES
################################################
echo "CREATE TABLES - cb_criteria"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"CREATE OR REPLACE TABLE \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
(
    id                  INT64,
    parent_id           INT64,
    domain_id           STRING,
    is_standard         INT64,
    type                STRING,
    subtype             STRING,
    concept_id          INT64,
    code                STRING,
    name                STRING,
    value               STRING,
    est_count           INT64,
    is_group            INT64,
    is_selectable       INT64,
    has_attribute       INT64,
    has_hierarchy       INT64,
    has_ancestor_data   INT64,
    path                STRING,
    synonyms            STRING
)"

# table that holds the ingredient --> coded drugs mapping
echo "CREATE TABLES - cb_criteria_ancestor"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"CREATE OR REPLACE TABLE \`$BQ_PROJECT.$BQ_DATASET.cb_criteria_ancestor\`
(
    ancestor_id INT64,
    descendant_id INT64
)"

# table that holds categorical results and min/max information about individual labs
echo "CREATE TABLES - cb_criteria_attribute"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"CREATE OR REPLACE TABLE \`$BQ_PROJECT.$BQ_DATASET.cb_criteria_attribute\`
(
    id                    INT64,
    concept_id            INT64,
    value_as_concept_id	  INT64,
    concept_name          STRING,
    type                  STRING,
    est_count             STRING
)"

# table that holds the drug brands to ingredients relationship mapping
echo "CREATE TABLES - cb_criteria_relationship"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"CREATE OR REPLACE TABLE \`$BQ_PROJECT.$BQ_DATASET.cb_criteria_relationship\`
(
    concept_id_1 INT64,
    concept_id_2 INT64
)"

echo "CREATE TABLES - atc_rel_in_data"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"CREATE OR REPLACE TABLE \`$BQ_PROJECT.$BQ_DATASET.atc_rel_in_data\`
(
    p_concept_id    INT64,
    p_concept_code  STRING,
    p_concept_name  STRING,
    p_domain_id     STRING,
    concept_id      INT64,
    concept_code    STRING,
    concept_name    STRING,
    domain_id       STRING
)"

echo "CREATE TABLES - loinc_rel_in_data"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"CREATE OR REPLACE TABLE \`$BQ_PROJECT.$BQ_DATASET.loinc_rel_in_data\`
(
    p_concept_id    INT64,
    p_concept_code  STRING,
    p_concept_name  STRING,
    p_domain_id     STRING,
    concept_id      INT64,
    concept_code    STRING,
    concept_name    STRING,
    domain_id       STRING
)"

echo "CREATE TABLES - snomed_rel_cm_in_data"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"CREATE OR REPLACE TABLE \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_cm_in_data\`
(
    p_concept_id    INT64,
    p_concept_code  STRING,
    p_concept_name  STRING,
    p_domain_id     STRING,
    concept_id      INT64,
    concept_code    STRING,
    concept_name    STRING,
    domain_id       STRING
)"

echo "CREATE TABLES - snomed_rel_cm_src_in_data"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"CREATE OR REPLACE TABLE \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_cm_src_in_data\`
(
    p_concept_id    INT64,
    p_concept_code  STRING,
    p_concept_name  STRING,
    p_domain_id     STRING,
    concept_id      INT64,
    concept_code    STRING,
    concept_name    STRING,
    domain_id       STRING
)"

echo "CREATE TABLES - snomed_rel_meas_in_data"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"CREATE OR REPLACE TABLE \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_meas_in_data\`
(
    p_concept_id    INT64,
    p_concept_code  STRING,
    p_concept_name  STRING,
    p_domain_id     STRING,
    concept_id      INT64,
    concept_code    STRING,
    concept_name    STRING,
    domain_id       STRING
)"

echo "CREATE TABLES - snomed_rel_pcs_in_data"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"CREATE OR REPLACE TABLE \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_pcs_in_data\`
(
    p_concept_id    INT64,
    p_concept_code  STRING,
    p_concept_name  STRING,
    p_domain_id     STRING,
    concept_id      INT64,
    concept_code    STRING,
    concept_name    STRING,
    domain_id       STRING
)"

echo "CREATE TABLES - snomed_rel_pcs_src_in_data"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"CREATE OR REPLACE TABLE \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_pcs_src_in_data\`
(
    p_concept_id    INT64,
    p_concept_code  STRING,
    p_concept_name  STRING,
    p_domain_id     STRING,
    concept_id      INT64,
    concept_code    STRING,
    concept_name    STRING,
    domain_id       STRING
)"


################################################
# CREATE VIEWS
################################################
echo "CREATE VIEWS - v_loinc_rel"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"CREATE OR REPLACE VIEW \`$BQ_PROJECT.$BQ_DATASET.v_loinc_rel\` AS
SELECT DISTINCT C1.CONCEPT_ID AS P_CONCEPT_ID, C1.CONCEPT_CODE AS P_CONCEPT_CODE,
    C1.CONCEPT_NAME AS P_CONCEPT_NAME, C2.CONCEPT_ID, C2.CONCEPT_CODE, C2.CONCEPT_NAME
FROM \`$BQ_PROJECT.$BQ_DATASET.concept_relationship\` CR,
    \`$BQ_PROJECT.$BQ_DATASET.concept\` C1,
    \`$BQ_PROJECT.$BQ_DATASET.concept\` C2,
    \`$BQ_PROJECT.$BQ_DATASET.relationship\` R
WHERE CR.CONCEPT_ID_1 = C1.CONCEPT_ID
    AND CR.CONCEPT_ID_2 = C2.CONCEPT_ID
    AND CR.RELATIONSHIP_ID = R.RELATIONSHIP_ID
    AND CR.RELATIONSHIP_ID = 'Subsumes'
    AND R.IS_HIERARCHICAL = '1'
    AND R.DEFINES_ANCESTRY = '1'
    AND C1.VOCABULARY_ID = 'LOINC'
    AND C2.VOCABULARY_ID = 'LOINC'
    AND C1.STANDARD_CONCEPT IN ('S','C')
    AND C2.STANDARD_CONCEPT IN ('S','C')
    AND C1.CONCEPT_CLASS_ID IN ('LOINC Hierarchy', 'Lab Test')
    AND C2.CONCEPT_CLASS_ID IN ('LOINC Hierarchy', 'Lab Test')"

echo "CREATE VIEWS - v_snomed_rel_cm"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"CREATE OR REPLACE VIEW \`$BQ_PROJECT.$BQ_DATASET.v_snomed_rel_cm\` AS
SELECT DISTINCT C1.CONCEPT_ID AS P_CONCEPT_ID, C1.CONCEPT_CODE AS P_CONCEPT_CODE, C1.CONCEPT_NAME AS P_CONCEPT_NAME,
    C1.DOMAIN_ID AS P_DOMAIN_ID, C2.CONCEPT_ID, C2.CONCEPT_CODE, C2.CONCEPT_NAME, C2.DOMAIN_ID
FROM \`$BQ_PROJECT.$BQ_DATASET.concept_relationship\` CR,
    \`$BQ_PROJECT.$BQ_DATASET.concept\` C1,
    \`$BQ_PROJECT.$BQ_DATASET.concept\` C2,
    \`$BQ_PROJECT.$BQ_DATASET.relationship\` R
WHERE CR.CONCEPT_ID_1 = C1.CONCEPT_ID
    AND CR.CONCEPT_ID_2 = C2.CONCEPT_ID
    AND CR.RELATIONSHIP_ID = R.RELATIONSHIP_ID
    AND C1.VOCABULARY_ID = 'SNOMED'
    AND C2.VOCABULARY_ID = 'SNOMED'
    AND C1.STANDARD_CONCEPT = 'S'
    AND C2.STANDARD_CONCEPT = 'S'
    AND R.IS_HIERARCHICAL = '1'
    AND R.DEFINES_ANCESTRY = '1'
    AND C1.DOMAIN_ID = 'Condition'
    AND C2.DOMAIN_ID = 'Condition'
    AND CR.RELATIONSHIP_ID = 'Subsumes'"

echo "CREATE VIEWS - v_snomed_rel_cm_src"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"CREATE OR REPLACE VIEW \`$BQ_PROJECT.$BQ_DATASET.v_snomed_rel_cm_src\` AS
SELECT DISTINCT C1.CONCEPT_ID AS P_CONCEPT_ID, C1.CONCEPT_CODE AS P_CONCEPT_CODE, C1.CONCEPT_NAME AS P_CONCEPT_NAME,
    C1.DOMAIN_ID AS P_DOMAIN_ID, C2.CONCEPT_ID, C2.CONCEPT_CODE, C2.CONCEPT_NAME, C2.DOMAIN_ID
FROM \`$BQ_PROJECT.$BQ_DATASET.concept_relationship\` CR,
    \`$BQ_PROJECT.$BQ_DATASET.concept\` C1,
    \`$BQ_PROJECT.$BQ_DATASET.concept\` C2,
    \`$BQ_PROJECT.$BQ_DATASET.relationship\` R
WHERE CR.CONCEPT_ID_1 = C1.CONCEPT_ID
    AND CR.CONCEPT_ID_2 = C2.CONCEPT_ID
    AND CR.RELATIONSHIP_ID = R.RELATIONSHIP_ID
    AND C1.VOCABULARY_ID = 'SNOMED'
    AND C2.VOCABULARY_ID = 'SNOMED'
    AND R.IS_HIERARCHICAL = '1'
    AND R.DEFINES_ANCESTRY = '1'
    AND C1.DOMAIN_ID = 'Condition'
    AND C2.DOMAIN_ID = 'Condition'
    AND CR.RELATIONSHIP_ID = 'Subsumes'"

echo "CREATE VIEWS - v_snomed_rel_meas"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"CREATE OR REPLACE VIEW \`$BQ_PROJECT.$BQ_DATASET.v_snomed_rel_meas\` AS
SELECT DISTINCT C1.CONCEPT_ID AS P_CONCEPT_ID, C1.CONCEPT_CODE AS P_CONCEPT_CODE, C1.CONCEPT_NAME AS P_CONCEPT_NAME,
    C1.DOMAIN_ID AS P_DOMAIN_ID, C2.CONCEPT_ID, C2.CONCEPT_CODE, C2.CONCEPT_NAME, C2.DOMAIN_ID
FROM \`$BQ_PROJECT.$BQ_DATASET.concept_relationship\` CR,
    \`$BQ_PROJECT.$BQ_DATASET.concept\` C1,
    \`$BQ_PROJECT.$BQ_DATASET.concept\` C2,
    \`$BQ_PROJECT.$BQ_DATASET.relationship\` R
WHERE CR.CONCEPT_ID_1 = C1.CONCEPT_ID
    AND CR.CONCEPT_ID_2 = C2.CONCEPT_ID
    AND CR.RELATIONSHIP_ID = R.RELATIONSHIP_ID
    AND C1.VOCABULARY_ID = 'SNOMED'
    AND C2.VOCABULARY_ID = 'SNOMED'
    AND C1.STANDARD_CONCEPT = 'S'
    AND C2.STANDARD_CONCEPT = 'S'
    AND R.IS_HIERARCHICAL = '1'
    AND R.DEFINES_ANCESTRY = '1'
    AND C1.DOMAIN_ID = 'Measurement'
    AND C2.DOMAIN_ID = 'Measurement'
    AND CR.RELATIONSHIP_ID = 'Subsumes'"

echo "CREATE VIEWS - v_snomed_rel_pcs"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"CREATE OR REPLACE VIEW \`$BQ_PROJECT.$BQ_DATASET.v_snomed_rel_pcs\` AS
SELECT DISTINCT C1.CONCEPT_ID AS P_CONCEPT_ID, C1.CONCEPT_CODE AS P_CONCEPT_CODE, C1.CONCEPT_NAME AS P_CONCEPT_NAME,
    C1.DOMAIN_ID AS P_DOMAIN_ID, C2.CONCEPT_ID, C2.CONCEPT_CODE, C2.CONCEPT_NAME, C2.DOMAIN_ID
FROM \`$BQ_PROJECT.$BQ_DATASET.concept_relationship\` CR,
    \`$BQ_PROJECT.$BQ_DATASET.concept\` C1,
    \`$BQ_PROJECT.$BQ_DATASET.concept\` C2,
    \`$BQ_PROJECT.$BQ_DATASET.relationship\` R
WHERE CR.CONCEPT_ID_1 = C1.CONCEPT_ID
    AND CR.CONCEPT_ID_2 = C2.CONCEPT_ID
    AND CR.RELATIONSHIP_ID = R.RELATIONSHIP_ID
    AND C1.VOCABULARY_ID = 'SNOMED'
    AND C2.VOCABULARY_ID = 'SNOMED'
    AND C1.STANDARD_CONCEPT = 'S'
    AND C2.STANDARD_CONCEPT = 'S'
    AND R.IS_HIERARCHICAL = '1'
    AND R.DEFINES_ANCESTRY = '1'
    AND C1.DOMAIN_ID = 'Procedure'
    AND C2.DOMAIN_ID = 'Procedure'
    AND CR.RELATIONSHIP_ID = 'Subsumes'"

echo "CREATE VIEWS - v_snomed_rel_pcs_src"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"CREATE OR REPLACE VIEW \`$BQ_PROJECT.$BQ_DATASET.v_snomed_rel_pcs_src\` AS
SELECT DISTINCT C1.CONCEPT_ID AS P_CONCEPT_ID, C1.CONCEPT_CODE AS P_CONCEPT_CODE, C1.CONCEPT_NAME AS P_CONCEPT_NAME,
    C1.DOMAIN_ID AS P_DOMAIN_ID, C2.CONCEPT_ID, C2.CONCEPT_CODE, C2.CONCEPT_NAME, C2.DOMAIN_ID
FROM \`$BQ_PROJECT.$BQ_DATASET.concept_relationship\` CR,
    \`$BQ_PROJECT.$BQ_DATASET.concept\` C1,
    \`$BQ_PROJECT.$BQ_DATASET.concept\` C2,
    \`$BQ_PROJECT.$BQ_DATASET.relationship\` R
WHERE CR.CONCEPT_ID_1 = C1.CONCEPT_ID
    AND CR.CONCEPT_ID_2 = C2.CONCEPT_ID
    AND CR.RELATIONSHIP_ID = R.RELATIONSHIP_ID
    AND C1.VOCABULARY_ID = 'SNOMED'
    AND C2.VOCABULARY_ID = 'SNOMED'
    AND R.IS_HIERARCHICAL = '1'
    AND R.DEFINES_ANCESTRY = '1'
    AND C1.DOMAIN_ID = 'Procedure'
    AND C2.DOMAIN_ID = 'Procedure'
    AND CR.RELATIONSHIP_ID = 'Subsumes'"


################################################
# SOURCE ICD9
################################################
echo "ICD9 - add data (do not insert zero count children)"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,subtype,concept_id,code,name,est_count,is_group,is_selectable,has_attribute,has_hierarchy,path)
select id, parent_id, a.domain_id, is_standard, type, subtype, a.concept_id, code, name,
    case when is_group = 0 and is_selectable = 1 then c.cnt else null end as est_count,
    is_group, is_selectable, has_attribute, has_hierarchy, path
from \`$BQ_PROJECT.$BQ_DATASET.prep_criteria\` a
left join
	(
		select *
		from \`$BQ_PROJECT.$BQ_DATASET.concept\`
		where (vocabulary_id in ('ICD9CM', 'ICD9Proc') and concept_code != '92')
			or (vocabulary_id = 'ICD9Proc' and concept_code = '92')
	) b on a.CODE = b.CONCEPT_CODE
left join
	(
		select concept_id, count(distinct person_id) cnt
		from \`$BQ_PROJECT.$BQ_DATASET.cb_search_all_events\`
		where is_standard = 0
			and concept_id in
				(
					select concept_id
				    from \`$BQ_PROJECT.$BQ_DATASET.prep_criteria\`
				    where type in ('ICD9CM', 'ICD9Proc')
			            and is_group = 0
			            and is_selectable = 1
				)
		group by 1
	) c on b.concept_id = c.concept_id
where type in ('ICD9CM', 'ICD9Proc')
    and (is_group = 1 or (is_group = 0 and is_selectable = 1 and (c.cnt != 0 or c.cnt is not null)))
order by 1"

echo "ICD9 - generate parent counts"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"UPDATE \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` x
SET x.est_count = y.cnt
from
	(
		select e.id, count(distinct person_id) cnt
		from
			(
				select *
				from
                    (
                        select id
                        from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
                        where type in ('ICD9CM', 'ICD9Proc')
                            and is_group = 1
                            and is_selectable = 1
                    ) a
				left join \`$BQ_PROJECT.$BQ_DATASET.prep_criteria_ancestor\` b on a.id = b.ancestor_id
			) e
		left join
    	  	(
				select c.id, d.*
				from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` c
				join
					(
						select a.person_id, a.concept_id
						from \`$BQ_PROJECT.$BQ_DATASET.cb_search_all_events\` a
						join
							(
    							select concept_id, path
    					    	from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    					    	where type in ('ICD9CM', 'ICD9Proc')
                                    and is_group = 0
                                    and is_selectable = 1
							) b on a.concept_id = b.concept_id
						where is_standard = 0
					) d on c.concept_id = d.concept_id
    	  	) f on e.descendant_id = f.id
		group by 1
	) y
where x.id = y.id"

echo "ICD9 - delete zero count parents"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"delete
from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
where type in ('ICD9CM', 'ICD9Proc')
    and is_selectable = 1
    and (est_count is null or est_count = 0)"

################################################
# SOURCE ICD10
################################################
echo "ICD10CM - insert data (do not insert zero count children)"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,subtype,concept_id,code,name,est_count,is_group,is_selectable,has_attribute,has_hierarchy,path)
select id, parent_id, a.domain_id, is_standard, type, subtype, a.concept_id, code, name,
    case when is_group = 0 and is_selectable = 1 then c.cnt else null end as est_count,
    is_group, is_selectable, has_attribute, has_hierarchy, path
from \`$BQ_PROJECT.$BQ_DATASET.prep_criteria\` a
left join
	(
		select *
		from \`$BQ_PROJECT.$BQ_DATASET.concept\`
		where vocabulary_id in ('ICD10CM')
	) b on a.CODE = b.CONCEPT_CODE
left join
	(
		select concept_id, count(distinct person_id) cnt
		from \`$BQ_PROJECT.$BQ_DATASET.cb_search_all_events\`
		where is_standard = 0
			and concept_id in
				(
					select concept_id
				    from \`$BQ_PROJECT.$BQ_DATASET.prep_criteria\`
				    where type = 'ICD10CM'
			            and is_group = 0
			            and is_selectable = 1
				)
		group by 1
	) c on b.concept_id = c.concept_id
where type = 'ICD10CM'
	and (is_group = 1 or (is_group = 0 and is_selectable = 1 and (c.cnt != 0 or c.cnt is not null)))
order by 1"

echo "ICD10CM - generate parent counts"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"UPDATE \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` x
SET x.est_count = y.cnt
from
	(
		select e.id, count(distinct person_id) cnt
		from
			(
				select *
				from
                    (
                        select id
                        from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
                            where type = 'ICD10CM'
                            and parent_id != 0
                            and is_group = 1
                    ) a
				left join \`$BQ_PROJECT.$BQ_DATASET.prep_criteria_ancestor\` b on a.id = b.ancestor_id
			) e
		left join
            (
                select c.id, d.*
			    from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` c
			    join
                    (
    					select a.person_id, a.concept_id
    					from \`$BQ_PROJECT.$BQ_DATASET.cb_search_all_events\` a
    					join
    						(
    							select concept_id, path
    					    	from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    					    	where type = 'ICD10CM'
    								and is_selectable = 1
    						) b on a.concept_id = b.concept_id
                        where is_standard = 0
                    ) d on c.concept_id = d.concept_id
            ) f on e.descendant_id = f.id
		group by 1
	) y
where x.id = y.id"

echo "ICD10PCS - insert data (do not insert zero count children)"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,subtype,concept_id,code,name,est_count,is_group,is_selectable,has_attribute,has_hierarchy,path)
select id, parent_id, a.domain_id, is_standard, type, subtype, a.concept_id, code, name,
    case when is_group = 0 and is_selectable = 1 then c.cnt else null end as est_count,
    is_group, is_selectable, has_attribute, has_hierarchy, path
from \`$BQ_PROJECT.$BQ_DATASET.prep_criteria\` a
left join
	(
		select *
		from \`$BQ_PROJECT.$BQ_DATASET.concept\`
		where vocabulary_id in ('ICD10PCS')
	) b on a.CODE = b.CONCEPT_CODE
left join
	(
		select concept_id, count(distinct person_id) cnt
		from \`$BQ_PROJECT.$BQ_DATASET.cb_search_all_events\`
		where is_standard = 0
			and concept_id in
				(
					select concept_id
				    from \`$BQ_PROJECT.$BQ_DATASET.prep_criteria\`
				    where type = 'ICD10PCS'
			            and is_group = 0
			            and is_selectable = 1
				)
		group by 1
	) c on b.concept_id = c.concept_id
where type = 'ICD10PCS'
	and (is_group = 1 or (is_group = 0 and is_selectable = 1 and (c.cnt != 0 or c.cnt is not null)))
order by 1"

echo "ICD10PCS - generate parent counts"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"UPDATE \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` x
SET x.est_count = y.cnt
from
    (
        select e.id, count(distinct person_id) cnt
        from
            (
                select *
                from
                    (
                        select id
                        from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
                        where type = 'ICD10PCS'
                            and parent_id != 0
                            and is_group = 1
                    ) a
                left join \`$BQ_PROJECT.$BQ_DATASET.prep_criteria_ancestor\` b on a.id = b.ancestor_id
            ) e
        left join
            (
                select c.id, d.*
                from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` c
                join
                    (
                        select a.person_id, a.concept_id
                        from \`$BQ_PROJECT.$BQ_DATASET.cb_search_all_events\` a
                        join
                            (
                                select concept_id, path
                                from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
                                where type = 'ICD10PCS'
                                    and is_group = 0
                                    and is_selectable = 1
                            ) b on a.concept_id = b.concept_id
                        where is_standard = 0
                    ) d on c.concept_id = d.concept_id
            ) f on e.descendant_id = f.id
        group by 1
    ) y
where x.id = y.id"

echo "ICD10 - delete zero count parents"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"delete
from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
where type in ('ICD10CM', 'ICD10PCS')
    and is_group = 1
    and is_selectable = 1
    and (est_count is null or est_count = 0)"


################################################
# SOURCE CPT
################################################
echo "CPT - insert data (do not insert zero count children)"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,subtype,concept_id,code,name,est_count,is_group,is_selectable,has_attribute,has_hierarchy,path)
select id, parent_id, a.domain_id, is_standard, type, subtype, a.concept_id, code, name,
    case when is_group = 0 and is_selectable = 1 then c.cnt else null end as est_count,
    is_group, is_selectable, has_attribute, has_hierarchy, path
from \`$BQ_PROJECT.$BQ_DATASET.prep_criteria\` a
left join
	(
		select *
		from \`$BQ_PROJECT.$BQ_DATASET.concept\`
		where vocabulary_id in ('CPT4')
	) b on a.CODE = b.CONCEPT_CODE
left join
	(
		select concept_id, count(distinct person_id) cnt
		from \`$BQ_PROJECT.$BQ_DATASET.cb_search_all_events\`
		where is_standard = 0
			and concept_id in
				(
					select concept_id
				    from \`$BQ_PROJECT.$BQ_DATASET.prep_criteria\`
				    where type = 'CPT4'
			            and is_group = 0
			            and is_selectable = 1
				)
		group by 1
	) c on b.concept_id = c.concept_id
where type = 'CPT4'
	and (is_group = 1 or (is_group = 0 and is_selectable = 1 and (c.cnt != 0 or c.cnt is not null)))
order by 1"

echo "CPT - generate parent counts"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"UPDATE \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` x
SET x.est_count = y.cnt
from
    (
        select e.id, count(distinct person_id) cnt
        from
            (
                select *
                from
                    (
                        select id
                        from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
                        where type = 'CPT4'
                            and parent_id != 0
                            and is_group = 1
                    ) a
                left join \`$BQ_PROJECT.$BQ_DATASET.prep_criteria_ancestor\` b on a.id = b.ancestor_id
            ) e
        left join
            (
                select c.id, d.*
                from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` c
                join
                    (
                        select a.person_id, a.concept_id
                        from \`$BQ_PROJECT.$BQ_DATASET.cb_search_all_events\` a
                        join
                            (
                                select concept_id, path
                                from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
                                where type = 'CPT4'
                                    and is_group = 0
                                    and is_selectable = 1
                            ) b on a.concept_id = b.concept_id
                        where is_standard = 0
                    ) d on c.concept_id = d.concept_id
            ) f on e.descendant_id = f.id
        group by 1
    ) y
where x.id = y.id"

echo "CPT - delete zero count parents"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"delete
from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
where type = 'CPT4'
    and
		(
			(parent_id != 0 and (est_count is null or est_count = 0))
			or
				(
					is_group = 1
					and id not in (select parent_id from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where type = 'CPT4' and est_count is not null)
				)
		)"


################################################
# PPI SURVEYS
################################################
echo "PPI SURVEYS - insert data"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,subtype,concept_id,name,value,est_count,is_group,is_selectable,has_attribute,has_hierarchy,path)
select id,parent_id,domain_id,is_standard,type,subtype,concept_id,name,value,
    case when is_selectable = 1 then 0 else null end as est_count,
    is_group,is_selectable,has_attribute,has_hierarchy,path
from \`$BQ_PROJECT.$BQ_DATASET.prep_criteria\`
where domain_id = 'SURVEY'
    and type = 'PPI'
order by 1"

echo "PPI SURVEYS - generate answer counts for all questions EXCEPT where question concept_id = 1585747"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"update \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` x
set x.est_count = y.cnt
from
    (
        select concept_id, CAST(value_source_concept_id as STRING) as value, count(distinct person_id) cnt
        from \`$BQ_PROJECT.$BQ_DATASET.cb_search_all_events\`
        where is_standard = 0
            and concept_id in
                (
                    select concept_id
                    from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
                    where domain_id = 'SURVEY'
                        and type = 'PPI'
                        and is_group = 1
                        and is_selectable = 1
                        and parent_id != 0
                        and concept_id != 1585747
                )
        group by 1,2
    ) y
where x.domain_id = 'SURVEY'
    and x.type = 'PPI'
    and x.concept_id = y.concept_id
    and x.value = y.value"

echo "PPI SURVEYS - generate answer counts for question (concept_id = 1585747)"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"update \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` x
set x.est_count = y.cnt
from
    (
        select concept_id, CAST(value_as_number as STRING) as value, count(distinct person_id) cnt
        from \`$BQ_PROJECT.$BQ_DATASET.cb_search_all_events\`
        where is_standard = 0
            and concept_id = 1585747
        group by 1,2
    ) y
where x.domain_id = 'SURVEY'
    and x.type = 'PPI'
    and x.is_group = 0
    and x.concept_id = y.concept_id
    and x.value = y.value"

echo "PPI SURVEYS - generate question counts"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"update \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` x
set x.est_count = y.cnt
from
    (
        SELECT concept_id, count(distinct person_id) cnt
        from \`$BQ_PROJECT.$BQ_DATASET.cb_search_all_events\`
        where is_standard = 0
            and concept_id in
                (
                    select concept_id
                    from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
                    where domain_id = 'SURVEY'
                        and type = 'PPI'
                        and is_group = 1
                        and is_selectable = 1
                        and parent_id != 0
                )
        group by 1
    ) y
where x.domain_id = 'SURVEY'
    and x.type = 'PPI'
    and x.is_group = 1
    and x.concept_id = y.concept_id"

echo "PPI SURVEYS - generate survey counts"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"UPDATE \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` x
SET x.est_count = y.cnt
from
    (
        select e.id, count(distinct person_id) cnt
        from
            (
                SELECT *
                FROM
                    (
                        SELECT id
                        FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
                        WHERE domain_id = 'SURVEY'
                            and type = 'PPI'
                            and parent_id = 0
                    ) a
                LEFT JOIN \`$BQ_PROJECT.$BQ_DATASET.prep_criteria_ancestor\` b on a.id = b.ancestor_id
            ) e
        left join
            (
                SELECT a.person_id, a.concept_id, b.id
                FROM \`$BQ_PROJECT.$BQ_DATASET.cb_search_all_events\` a
                JOIN
                    (
                        SELECT id, concept_id
                        FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
                        WHERE domain_id = 'SURVEY'
                            and type = 'PPI'
                            and is_group = 1
                            and is_selectable = 1
                            and parent_id != 0
                    ) b on a.concept_id = b.concept_id
                WHERE a.is_standard = 0
            ) f on e.descendant_id = f.id
        group by 1
    ) y
where x.domain_id = 'SURVEY'
    and x.type = 'PPI'
    and x.id = y.id"


################################################
# PPI PHYSICAL MEASUREMENTS (PM)
################################################
echo "PM - insert data"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,subtype,concept_id,name,value,est_count,is_group,is_selectable,has_attribute,has_hierarchy)
select id,parent_id,domain_id,is_standard,type,subtype,concept_id,name,value,
    case when is_selectable = 1 then 0 else null end as est_count,
    is_group,is_selectable,has_attribute,has_hierarchy
from \`$BQ_PROJECT.$BQ_DATASET.prep_criteria\`
where domain_id = 'PHYSICAL_MEASUREMENT'
order by 1"

echo "PM - counts"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"update \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` x
set x.est_count = y.cnt
from
    (
        select measurement_source_concept_id as concept_id, count(distinct person_id) as cnt
        from \`$BQ_PROJECT.$BQ_DATASET.measurement\`
        where measurement_source_concept_id in (903126,903133,903121,903124,903135,903136)
        group by 1
    ) y
where x.domain_id = 'PHYSICAL_MEASUREMENT'
    and x.concept_id = y.concept_id"

echo "PM - counts for heart rhythm, pregnancy, and wheelchair use"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"update \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` x
set x.est_count = y.cnt
from
    (
        select measurement_source_concept_id as concept_id, CAST(value_as_concept_id as STRING) as value, count(distinct person_id) as cnt
        from \`$BQ_PROJECT.$BQ_DATASET.measurement\`
        where measurement_source_concept_id IN (1586218, 903120, 903111)
        group by 1,2
    ) y
where x.domain_id = 'PHYSICAL_MEASUREMENT'
    and x.concept_id = y.concept_id
    and x.value = y.value"

#----- BLOOD PRESSURE -----
echo "PM - blood pressure  - hypotensive"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"update \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
set est_count =
    (
        select count(distinct person_id)
        from \`$BQ_PROJECT.$BQ_DATASET.cb_search_all_events\`
        where concept_id in (903115, 903118)
            and systolic <= 90
            and diastolic <= 60
    )
where domain_id = 'PHYSICAL_MEASUREMENT'
    and subtype = 'BP'
    and name LIKE 'Hypotensive%'"

echo "PM - blood pressure  - normal"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"update \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
set est_count =
    (
        select count(distinct person_id)
        from \`$BQ_PROJECT.$BQ_DATASET.cb_search_all_events\`
        where concept_id in (903115, 903118)
            and systolic <= 120
            and diastolic <= 80
    )
where domain_id = 'PHYSICAL_MEASUREMENT'
    and subtype = 'BP'
    and name LIKE 'Normal%'"

echo "PM - blood pressure  - pre-hypertensive"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"update \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
set est_count =
    (
        select count(distinct person_id)
        from \`$BQ_PROJECT.$BQ_DATASET.cb_search_all_events\`
        where concept_id in (903115, 903118)
            and systolic BETWEEN 120 AND 139
            and diastolic BETWEEN 81 AND 89
    )
where domain_id = 'PHYSICAL_MEASUREMENT'
    and subtype = 'BP'
    and name LIKE 'Pre-Hypertensive%'"

echo "PM - blood pressure  - hypertensive"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"update \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
set est_count =
    (
        select count(distinct person_id)
        from \`$BQ_PROJECT.$BQ_DATASET.cb_search_all_events\`
        where concept_id in (903115, 903118)
            and systolic >= 140
            and diastolic >= 90
    )
where domain_id = 'PHYSICAL_MEASUREMENT'
    and subtype = 'BP'
    and name LIKE 'Hypertensive%'"

echo "PM - blood pressure  - detail"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"update \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
set est_count =
    (
        select count(distinct person_id)
        from \`$BQ_PROJECT.$BQ_DATASET.cb_search_all_events\`
        where concept_id in (903115, 903118)
    )
where domain_id = 'PHYSICAL_MEASUREMENT'
    and subtype = 'BP'
    and name = 'Blood Pressure Detail'"


################################################
# DEMOGRAPHICS
################################################
echo "DEMO - Age parent"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,name,is_group,is_selectable,has_attribute,has_hierarchy)
select (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`)+1 AS ID,
    0,'PERSON',1,'AGE','Age',1,0,0,0"

echo "DEMO - Age Children"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,name,value,est_count,is_group,is_selectable,has_attribute,has_hierarchy)
select row_num + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) AS ID,
    (SELECT ID FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` WHERE type = 'AGE' and parent_id = 0) as parent_id,
    'PERSON',1,'AGE', CAST(row_num AS STRING) as name, CAST(row_num as STRING) as value,
    case when b.cnt is null then 0 else b.cnt end as est_count,
    0,1,0,0
from
    (
        select ROW_NUMBER() OVER(ORDER BY person_id) as row_num
        from \`$BQ_PROJECT.$BQ_DATASET.person\`
        order by person_id limit 120
    ) a
left join
    (
        select CAST(FLOOR(DATE_DIFF(CURRENT_DATE(), DATE(birth_datetime), MONTH)/12) as INT64) as age, count(*) as cnt
        from \`$BQ_PROJECT.$BQ_DATASET.person\`
        where person_id not in
            (
                select person_id
                from \`$BQ_PROJECT.$BQ_DATASET.death\`
            )
        group by 1
    ) b on a.row_num = b.age
order by 1"

echo "DEMO - Deceased"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,name,est_count,is_group,is_selectable,has_attribute,has_hierarchy)
select (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`)+1 AS ID,
    0,'PERSON',1,'DECEASED','Deceased',
    (select count(distinct person_id) from \`$BQ_PROJECT.$BQ_DATASET.death\`),
    0,1,0,0"

echo "DEMO - Gender parent"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,name,is_group,is_selectable,has_attribute,has_hierarchy)
select (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`)+1 AS ID,
    0,'PERSON',1,'GENDER','Gender',1,0,0,0"

echo "DEMO - Gender children"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,concept_id,name,est_count,is_group,is_selectable,has_attribute,has_hierarchy)
select ROW_NUMBER() OVER(ORDER BY concept_id) + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) AS ID,
    (SELECT ID FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` WHERE type = 'GENDER' and parent_id = 0) as parent_id,
    'PERSON',1,'GENDER',concept_id,
    CONCAT( UPPER(SUBSTR(concept_name, 1, 1)), LOWER(SUBSTR(concept_name, 2)) ) as name,
    b.cnt,0,1,0,0
from \`$BQ_PROJECT.$BQ_DATASET.concept\` a
left join
    (
        select gender_concept_id, count(distinct person_id) cnt
        from \`$BQ_PROJECT.$BQ_DATASET.person\`
        group by 1
    ) b on a.concept_id = b.gender_concept_id
where domain_id = 'Gender'
    and standard_concept = 'S'
    and b.cnt is not null"

echo "DEMO - Race parent"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,name,is_group,is_selectable,has_attribute,has_hierarchy)
select (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`)+1 AS ID,
    0,'PERSON',1,'RACE','Race',1,0,0,0"

echo "DEMO - Race children"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,concept_id,name,est_count,is_group,is_selectable,has_attribute,has_hierarchy)
select ROW_NUMBER() OVER(ORDER BY concept_id) + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) AS ID,
    (SELECT ID FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` WHERE type = 'RACE' and parent_id = 0) as parent_id,
    'PERSON',1,'RACE',concept_id,
    CONCAT( UPPER(SUBSTR(concept_name, 1, 1)), LOWER(SUBSTR(concept_name, 2)) ) as name,
    b.cnt,0,1,0,0
from \`$BQ_PROJECT.$BQ_DATASET.concept\` a
left join
    (
        select race_concept_id, count(distinct person_id) cnt
        from \`$BQ_PROJECT.$BQ_DATASET.person\`
        group by 1
    ) b on a.concept_id = b.race_concept_id
where domain_id = 'Race'
    and standard_concept = 'S'
    and b.cnt is not null"

echo "DEMO - Ethnicity parent"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,name,is_group,is_selectable,has_attribute,has_hierarchy)
select (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`)+1 AS ID,
    0,'PERSON',1,'ETHNICITY','Ethnicity',1,0,0,0"

echo "DEMO - Ethnicity children"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,concept_id,name,est_count,is_group,is_selectable,has_attribute,has_hierarchy)
select ROW_NUMBER() OVER(ORDER BY concept_id) + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) AS ID,
    (SELECT ID FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` WHERE type = 'ETHNICITY' and parent_id = 0) as parent_id,
    'PERSON',1,'ETHNICITY',concept_id,
    CONCAT( UPPER(SUBSTR(concept_name, 1, 1)), LOWER(SUBSTR(concept_name, 2)) ) as name,
    b.cnt,0,1,0,0
from \`$BQ_PROJECT.$BQ_DATASET.concept\` a
left join
    (
        select ethnicity_concept_id, count(distinct person_id) cnt
        from \`$BQ_PROJECT.$BQ_DATASET.person\`
        group by 1
    ) b on a.concept_id = b.ethnicity_concept_id
where domain_id = 'Ethnicity'
    and standard_concept = 'S'
    and b.cnt is not null"


################################################
# VISITS
################################################
echo "VISITS - add items with counts"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"INSERT INTO \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,concept_id,name,est_count,is_group,is_selectable,has_attribute,has_hierarchy)
SELECT ROW_NUMBER() OVER(order by concept_name) + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as id,
    0,'VISIT',1,'VISIT',concept_id,concept_name,a.cnt,0,1,0,0
FROM
    (
        select visit_concept_id, count(distinct person_id) cnt
        from \`$BQ_PROJECT.$BQ_DATASET.visit_occurrence\`
        group by 1
    ) a
LEFT JOIN \`$BQ_PROJECT.$BQ_DATASET.concept\` b ON a.visit_concept_id = b.concept_id
where b.vocabulary_id = 'Visit'"


################################################
# CONDITIONS
################################################
# ----- SOURCE SNOMED -----
echo "CONDITIONS - SOURCE SNOMED - temp table level 0"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_cm_src_in_data\`
    (p_concept_id, p_concept_code, p_concept_name, p_domain_id, concept_id, concept_code, concept_name, domain_id)
select *
from \`$BQ_PROJECT.$BQ_DATASET.v_snomed_rel_cm_src\` a
where concept_id in
    (
        select distinct condition_source_concept_id
        from \`$BQ_PROJECT.$BQ_DATASET.condition_occurrence\` a
        left join \`$BQ_PROJECT.$BQ_DATASET.concept\` b on a.condition_source_concept_id = b.concept_id
        where condition_source_concept_id != 0
            and b.domain_id = 'Condition'
            and b.vocabulary_id = 'SNOMED'
    )"

# currently, there are only 5 levels, but we run it 6 times to be safe
for i in {1..6};
do
    echo "CONDITIONS - SOURCE SNOMED - temp table level $i"
    bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
    "insert into \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_cm_src_in_data\`
        (p_concept_id, p_concept_code, p_concept_name, p_domain_id, concept_id, concept_code, concept_name, domain_id)
    select *
    from \`$BQ_PROJECT.$BQ_DATASET.v_snomed_rel_cm_src\` a
    where concept_id in
        (
            select P_CONCEPT_ID
            from \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_cm_src_in_data\`
        )
        and concept_id not in
            (
                select CONCEPT_ID
                from \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_cm_src_in_data\`
            )"
done

echo "CONDITIONS - SOURCE SNOMED - add root"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,concept_id,code,name,is_group,is_selectable,has_attribute,has_hierarchy,path)
select (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`)+1 AS ID,
    0,'CONDITION',0,'SNOMED',concept_id,concept_code,concept_name,1,0,0,1,
    CAST((SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`)+1 as STRING) as path
from \`$BQ_PROJECT.$BQ_DATASET.concept\`
where concept_id = 441840"

echo "CONDITIONS - SOURCE SNOMED - add level 0"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,concept_id,code,name,is_group,is_selectable,has_attribute,has_hierarchy,path)
select row_number() over (order by p.id, c.concept_name)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`),
    p.id,'CONDITION',0,'SNOMED',c.concept_id,c.concept_code,c.concept_name,1,1,0,1,
    CONCAT(p.path, '.',
        CAST(row_number() over (order by p.id, c.concept_name)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) AS STRING))
from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` p
join \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_cm_src_in_data\` c on p.code = c.p_concept_code
where p.domain_id = 'CONDITION'
    and p.type = 'SNOMED'
    and p.is_standard = 0
    and p.id not in
        (
            select parent_id
            from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
        )
    and c.concept_id in
        (
            select p_concept_id
            from \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_cm_src_in_data\`
        )"

# currently, there are only 16 levels, but we run it 18 times to be safe (if changed, change number of joins in next query)
for i in {1..18};
do
    echo "CONDITIONS - SOURCE SNOMED - add level $i"
    bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
    "insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
        (id,parent_id,domain_id,is_standard,type,concept_id,code,name,is_group,is_selectable,has_attribute,has_hierarchy,path)
    select row_number() over (order by p.id, c.concept_name)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`),
        p.id,'CONDITION',0,'SNOMED',c.concept_id,c.concept_code,c.concept_name,
        case when l.concept_code is null then 1 else 0 end,
        1,0,1,
        CONCAT(p.path, '.',
            CAST(row_number() over (order by p.id, c.concept_name)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as STRING))
    from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` p
    join \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_cm_src_in_data\` c on p.code = c.p_concept_code
    left join
        (
            select distinct a.concept_code
            from \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_cm_src_in_data\` a
            left join \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_cm_src_in_data\` b on a.concept_id = b.p_concept_id
            where b.concept_id is null
        ) l on c.concept_code = l.concept_code
    where p.domain_id = 'CONDITION'
        and p.type = 'SNOMED'
        and p.is_standard = 0
        and p.id not in
            (
                select parent_id
                from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
            )"
done

# if loop count above is changed, the number of JOINS below must be updated
echo "CONDITIONS - SOURCE SNOMED - add data into ancestor table"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.prep_criteria_ancestor\` (ancestor_id, descendant_id)
select distinct a.ID as ancestor_id,
    coalesce(t.id, s.id, r.id, q.id, p.id, o.id, n.ID, m.ID, k.ID, j.ID, i.ID, h.ID, g.ID, f.ID, e.ID, d.ID, c.ID, b.ID) as descendant_id
from (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'CONDITION' and type = 'SNOMED' and is_standard = 0) a
    join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'CONDITION' and type = 'SNOMED' and is_standard = 0) b on a.ID = b.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'CONDITION' and type = 'SNOMED' and is_standard = 0) c on b.ID = c.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'CONDITION' and type = 'SNOMED' and is_standard = 0) d on c.ID = d.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'CONDITION' and type = 'SNOMED' and is_standard = 0) e on d.ID = e.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'CONDITION' and type = 'SNOMED' and is_standard = 0) f on e.ID = f.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'CONDITION' and type = 'SNOMED' and is_standard = 0) g on f.ID = g.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'CONDITION' and type = 'SNOMED' and is_standard = 0) h on g.ID = h.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'CONDITION' and type = 'SNOMED' and is_standard = 0) i on h.ID = i.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'CONDITION' and type = 'SNOMED' and is_standard = 0) j on i.ID = j.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'CONDITION' and type = 'SNOMED' and is_standard = 0) k on j.ID = k.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'CONDITION' and type = 'SNOMED' and is_standard = 0) m on k.ID = m.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'CONDITION' and type = 'SNOMED' and is_standard = 0) n on m.ID = n.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'CONDITION' and type = 'SNOMED' and is_standard = 0) o on n.ID = o.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'CONDITION' and type = 'SNOMED' and is_standard = 0) p on o.ID = p.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'CONDITION' and type = 'SNOMED' and is_standard = 0) q on p.ID = q.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'CONDITION' and type = 'SNOMED' and is_standard = 0) r on q.ID = r.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'CONDITION' and type = 'SNOMED' and is_standard = 0) s on r.ID = s.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'CONDITION' and type = 'SNOMED' and is_standard = 0) t on s.ID = t.PARENT_ID
where a.parent_id != 0 and a.is_group = 1"

echo "CONDITIONS - SOURCE SNOMED - child counts"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"update \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` x
set x.est_count = y.cnt
from
    (
        select condition_source_concept_id as concept_id, count(distinct person_id) cnt
        from \`$BQ_PROJECT.$BQ_DATASET.condition_occurrence\`
        group by 1
    ) y
where x.concept_id = y.concept_id
    and x.domain_id = 'CONDITION'
    and x.type = 'SNOMED'
    and x.is_standard = 0
    and x.is_group = 0
    and x.is_selectable = 1"

echo "CONDITIONS - SOURCE SNOMED - parent counts"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"UPDATE \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` x
SET x.est_count = y.cnt
from
    (
        select e.id, count(distinct person_id) cnt
        from
            (
                select *
                from
                    (
                        select id
                        from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
                        where domain_id = 'CONDITION'
                            and type = 'SNOMED'
                            and is_standard = 0
                            and parent_id != 0
                            and is_group = 1
                    ) a
                left join \`$BQ_PROJECT.$BQ_DATASET.prep_criteria_ancestor\` b on a.id = b.ancestor_id
            ) e
        left join
            (
                select c.id, d.*
                from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` c
                join
                    (
                        select a.person_id, a.condition_source_concept_id as concept_id
                        from \`$BQ_PROJECT.$BQ_DATASET.condition_occurrence\` a
                        join
                            (
                                select concept_id, path
                                from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
                                where domain_id = 'CONDITION'
                                    and type = 'SNOMED'
                                    and is_standard = 0
                                    and is_group = 0
                                    and is_selectable = 1
                            ) b on a.condition_source_concept_id = b.concept_id
                    ) d on c.concept_id = d.concept_id
            ) f on e.descendant_id = f.id
        group by 1
    ) y
where x.id = y.id"

# ----- STANDARD SNOMED -----
echo "CONDITIONS - STANDARD SNOMED - temp table level 0"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_cm_in_data\`
    (p_concept_id, p_concept_code, p_concept_name, p_domain_id, concept_id, concept_code, concept_name, domain_id)
select *
from \`$BQ_PROJECT.$BQ_DATASET.v_snomed_rel_cm\` a
where concept_id in
    (
        select distinct condition_concept_id
        from \`$BQ_PROJECT.$BQ_DATASET.condition_occurrence\` a
        left join \`$BQ_PROJECT.$BQ_DATASET.concept\` b on a.condition_concept_id = b.concept_id
        where condition_concept_id != 0
            and b.domain_id = 'Condition'
            and b.standard_concept = 'S'
            and b.vocabulary_id = 'SNOMED'
    )"

# currently, there are only 5 levels, but we run it 6 times to be safe
for i in {1..6};
do
    echo "CONDITIONS - STANDARD SNOMED - temp table level $i"
    bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
    "insert into \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_cm_in_data\`
        (p_concept_id, p_concept_code, p_concept_name, p_domain_id, concept_id, concept_code, concept_name, domain_id)
    select *
    from \`$BQ_PROJECT.$BQ_DATASET.v_snomed_rel_cm\` a
    where concept_id in
        (
            select P_CONCEPT_ID
            from \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_cm_in_data\`
        )
      and concept_id not in
        (
            select CONCEPT_ID
            from \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_cm_in_data\`
        )"
done

echo "CONDITIONS - STANDARD SNOMED - add root"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,concept_id,code,name,is_group,is_selectable,has_attribute,has_hierarchy,path)
select (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`)+1 AS ID,
    0,'CONDITION',1,'SNOMED',concept_id,concept_code,concept_name,1,0,0,1,
    CAST((SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`)+1 as STRING) as path
from \`$BQ_PROJECT.$BQ_DATASET.concept\`
where concept_id = 441840"

echo "CONDITIONS - STANDARD SNOMED - add level 0"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,concept_id,code,name,is_group,is_selectable,has_attribute,has_hierarchy,path)
select row_number() over (order by p.id, c.concept_name)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`),
    p.id,'CONDITION',1,'SNOMED',c.concept_id,c.concept_code,c.concept_name,1,1,0,1,
    CONCAT(p.path, '.',
        CAST(row_number() over (order by p.id, c.concept_name)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) AS STRING))
from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` p
join \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_cm_in_data\` c on p.code = c.p_concept_code
where p.domain_id = 'CONDITION'
    and p.type = 'SNOMED'
    and p.is_standard = 1
    and p.id not in
        (
            select parent_id
            from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
        )
    and c.concept_id in
        (
            select p_concept_id
            from \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_cm_in_data\`
        )"

# currently, there are only 17 levels, but we run it 18 times to be safe
for i in {1..18};
do
    echo "CONDITIONS - STANDARD SNOMED - add level $i"
    bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
    "insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
        (id,parent_id,domain_id,is_standard,type,concept_id,code,name,is_group,is_selectable,has_attribute,has_hierarchy,path)
    select row_number() over (order by p.id, c.concept_name)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`),
        p.id,'CONDITION',1,'SNOMED',c.concept_id,c.concept_code,c.concept_name,
        case when l.concept_code is null then 1 else 0 end,
        1,0,1,
        CONCAT(p.path, '.',
            CAST(row_number() over (order by p.id, c.concept_name)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as STRING))
    from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` p
    join \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_cm_in_data\` c on p.code = c.p_concept_code
    left join
        (
            select distinct a.CONCEPT_CODE
            from \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_cm_in_data\` a
            left join \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_cm_in_data\` b on a.concept_id = b.p_concept_id
            where b.concept_id is null
        ) l on c.concept_code = l.concept_code
    where p.domain_id = 'CONDITION'
        and p.type = 'SNOMED'
        and p.is_standard = 1
        and p.id not in
            (
                select PARENT_ID
                from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
            )"
done

echo "CONDITIONS - STANDARD SNOMED - child counts"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"update \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` x
set x.est_count = y.cnt
from
    (
        select condition_concept_id as concept_id, count(distinct person_id) cnt
        from \`$BQ_PROJECT.$BQ_DATASET.condition_occurrence\`
        group by 1
    ) y
where x.concept_id = y.concept_id
    and x.domain_id = 'CONDITION'
    and x.type = 'SNOMED'
    and x.is_standard = 1
    and x.is_group = 0
    and x.is_selectable = 1"

echo "CONDITIONS - STANDARD SNOMED - parent counts"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"UPDATE \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` x
SET x.est_count = y.cnt
from
    (
        select ancestor_concept_id as concept_id, count(distinct person_id) cnt
        from
            (
                select *
                from \`$BQ_PROJECT.$BQ_DATASET.concept_ancestor\`
                where ancestor_concept_id in
                    (
                        select distinct concept_id
                        from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
                        where domain_id = 'CONDITION'
                            and type = 'SNOMED'
                            and is_standard = 1
                            and parent_id != 0
                            and is_group = 1
                    )
            ) a
        join \`$BQ_PROJECT.$BQ_DATASET.condition_occurrence\` b on a.descendant_concept_id = b.condition_concept_id
        group by 1
    ) y
where x.concept_id = y.concept_id
    and x.domain_id = 'CONDITION'
    and x.type = 'SNOMED'
    and x.is_standard = 1
    and x.is_group = 1"

#----- OTHER STANDARD VOCABULARIES -----
echo "CONDITIONS - add other Standard Concepts"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,concept_id,code,name,est_count,is_group,is_selectable,has_attribute,has_hierarchy,path)
select ROW_NUMBER() OVER(order by vocabulary_id,concept_name) + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as ID,
    0, 'PROCEDURE',1, vocabulary_id,concept_id,concept_code,concept_name,est_count,0,1,0,0,
    CAST(ROW_NUMBER() OVER(order by vocabulary_id,concept_name) + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as STRING) as path
from
    (
        select concept_name, vocabulary_id, concept_id, concept_code, count(distinct person_id) est_count
        from \`$BQ_PROJECT.$BQ_DATASET.condition_occurrence\` a
        left join \`$BQ_PROJECT.$BQ_DATASET.concept\` b on a.condition_concept_id = b.concept_id
        where standard_concept = 'S'
            and domain_id = 'Condition'
            and vocabulary_id not in ('SNOMED')
        group by 1,2,3,4
    ) x"


################################################
# MEASUREMENTS
################################################
echo "MEASUREMENTS - add clinical root"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,subtype,concept_id,code,name,is_group,is_selectable,has_attribute,has_hierarchy,path)
SELECT (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`)+1 as ID,
    0,'MEASUREMENT',1,'LOINC','CLIN',36207527,'LP248771-0','Clinical',1,0,0,1,
    CAST((SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`)+1 AS STRING)"

echo "MEASUREMENTS - add lab root"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,subtype,concept_id,code,name,is_group,is_selectable,has_attribute,has_hierarchy,path)
SELECT (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`)+1 as ID,
    0,'MEASUREMENT',1,'LOINC','LAB',36206173,'LP29693-6','Lab',1,0,0,1,
    CAST((SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`)+1 AS STRING)"

# ----- LOINC CLINICAL -----
echo "MEASUREMENTS - clinical - add parents"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,subtype,name,is_group,is_selectable,has_attribute,has_hierarchy,path)
SELECT ROW_NUMBER() OVER(order by name) + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as ID,
    (SELECT ID FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` WHERE type = 'LOINC' and subtype = 'CLIN') as parent_id,
    'MEASUREMENT',1,'LOINC','CLIN',name,1,0,0,1,
    CONCAT( (SELECT PATH FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` WHERE type = 'LOINC' and subtype = 'CLIN'), '.',
        CAST(ROW_NUMBER() OVER(order by name) + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) AS STRING) )
from
    (
        select distinct parent as name
        from \`$BQ_PROJECT.$BQ_DATASET.prep_clinical_terms_nc\` a
        left join \`$BQ_PROJECT.$BQ_DATASET.concept\` b using (concept_id)
        where b.concept_id in
            (
                select distinct measurement_concept_id
                from \`$BQ_PROJECT.$BQ_DATASET.measurement\`
            )
    ) x"

# add items with vocabulary_id = 'LOINC' and concept_class_id = 'Clinical Observation' where we have categorized them
echo "MEASUREMENTS - clinical - add children"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,subtype,concept_id,code,name,est_count,is_group,is_selectable,has_attribute,has_hierarchy,path)
select ROW_NUMBER() OVER(order by parent_id, concept_name) + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as ID,
    parent_id,'MEASUREMENT',1,'LOINC','CLIN',concept_id,concept_code,concept_name,est_count,0,1,0,1,
    CONCAT(parent_path, '.',
        CAST(ROW_NUMBER() OVER(order by parent_id, concept_name) + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) AS STRING))
from
    (
        select z.*, y.id as parent_id, y.path as parent_path
        from \`$BQ_PROJECT.$BQ_DATASET.prep_clinical_terms_nc\` x
        join
            (
                select id,name,path
                from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
                where type = 'LOINC'
                    and subtype = 'CLIN'
                    and is_group = 1
            ) y on x.parent = y.name
        join
            (
                select concept_name, concept_id, concept_code, count(distinct person_id) est_count
                from \`$BQ_PROJECT.$BQ_DATASET.measurement\` a
                left join \`$BQ_PROJECT.$BQ_DATASET.concept\` b on a.measurement_concept_id = b.concept_id
                where standard_concept = 'S'
                    and domain_id = 'Measurement'
                    and vocabulary_id = 'LOINC'
                group by 1,2,3
            ) z on x.concept_id = z.concept_id
    ) g"

#----- LOINC LABS -----
echo "MEASUREMENTS - labs - load temp table 0"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.loinc_rel_in_data\`
    (p_concept_id, p_concept_code, p_concept_name, concept_id, concept_code, concept_name)
select *
from \`$BQ_PROJECT.$BQ_DATASET.v_loinc_rel\` a
where concept_id in
    (
        select distinct MEASUREMENT_CONCEPT_ID
        from \`$BQ_PROJECT.$BQ_DATASET.measurement\` a
        left join \`$BQ_PROJECT.$BQ_DATASET.concept\` b on a.MEASUREMENT_CONCEPT_ID = b.concept_id
        where MEASUREMENT_CONCEPT_ID != 0
            and b.vocabulary_id = 'LOINC'
            and b.STANDARD_CONCEPT = 'S'
            and b.domain_id = 'Measurement'
    )"

# currently, there are only 4 levels, but we run it 5 times to be safe
for i in {1..5};
do
    echo "MEASUREMENTS - labs - load temp table $i"
    bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
    "insert into \`$BQ_PROJECT.$BQ_DATASET.loinc_rel_in_data\`
        (p_concept_id, p_concept_code, p_concept_name, concept_id, concept_code, concept_name)
    select *
    from \`$BQ_PROJECT.$BQ_DATASET.v_loinc_rel\` a
    where concept_id in
        (
            select P_CONCEPT_ID
            from \`$BQ_PROJECT.$BQ_DATASET.loinc_rel_in_data\`
        )
        and concept_id not in
            (
                select CONCEPT_ID
                from \`$BQ_PROJECT.$BQ_DATASET.loinc_rel_in_data\`
            )"
done

echo "MEASUREMENTS - labs - add roots - level 0"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,subtype,concept_id,code,name,is_group,is_selectable,has_attribute,has_hierarchy,path)
select row_number() over (order by t.ID, b.CONCEPT_NAME)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`),
    t.ID,'MEASUREMENT',1,'LOINC','LAB',b.CONCEPT_ID,b.CONCEPT_CODE,b.CONCEPT_NAME,1,0,0,1,
    CONCAT( t.path, '.',
        CAST(row_number() over (order by t.ID, b.CONCEPT_NAME)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) AS STRING) )
from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` t
join \`$BQ_PROJECT.$BQ_DATASET.loinc_rel_in_data\` b on t.code = b.p_concept_code
where (t.id) not in (select PARENT_ID from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`)
    and t.type = 'LOINC'
    and t.subtype = 'LAB'
    and b.concept_id in
        (
            select p_concept_id
            from \`$BQ_PROJECT.$BQ_DATASET.loinc_rel_in_data\`
        )"

# for each loop, add all items (children/parents) directly under the items that were previously added
# currently, there are only 11 levels, but we run it 12 times to be safe
# if this number is changed, you will need to change the number of JOINS in the query below adding data to the ancestor table
for i in {1..12};
do
    echo "MEASUREMENTS - labs - add level $i"
    bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
    "insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
        (id,parent_id,domain_id,is_standard,type,subtype,concept_id,code,name,est_count,is_group,is_selectable,has_attribute,has_hierarchy,path)
    select row_number() over (order by t.ID, b.CONCEPT_NAME)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`),
        t.ID, 'MEASUREMENT',1,'LOINC','LAB',b.CONCEPT_ID,b.CONCEPT_CODE, b.CONCEPT_NAME,
        case when l.CONCEPT_CODE is null then null else m.cnt end as est_count,
        case when l.CONCEPT_CODE is null then 1 else 0 end as is_group,
        case when l.CONCEPT_CODE is null then 0 else 1 end as is_selectable,
        0,1,
        CONCAT(t.path, '.',
            CAST(row_number() over (order by t.ID, b.CONCEPT_NAME)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as STRING))
    from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` t
    join \`$BQ_PROJECT.$BQ_DATASET.loinc_rel_in_data\` b on t.code = b.p_concept_code
    left join
        (
            select distinct a.CONCEPT_CODE
            from \`$BQ_PROJECT.$BQ_DATASET.loinc_rel_in_data\` a
            left join \`$BQ_PROJECT.$BQ_DATASET.loinc_rel_in_data\` b on a.CONCEPT_ID = b.P_CONCEPT_ID
            where b.CONCEPT_ID is null
        ) l on b.CONCEPT_CODE = l.CONCEPT_CODE
    left join
        (
            select measurement_concept_id, count(distinct person_id) cnt
            from \`$BQ_PROJECT.$BQ_DATASET.measurement\`
            group by 1
        ) m on b.concept_id = m.measurement_concept_id
    where
        t.id not in
            (
                select parent_id
                from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
                where type = 'LOINC'
                    and subtype = 'LAB'
            )
        and parent_id != 0"
done

echo "MEASUREMENTS - labs - add parent for uncategorized labs"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,subtype,name,is_group,is_selectable,has_attribute,has_hierarchy,path)
SELECT (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`)+1 as ID,
    a.id as parent_id,'MEASUREMENT',1,'LOINC','LAB','Uncategorized',1,0,0,1,
    CONCAT(a.path, '.', CAST((SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`)+1 AS STRING))
FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` a
WHERE type = 'LOINC' and subtype = 'LAB' and parent_id = 0"

echo "MEASUREMENTS - labs - add uncategorized labs"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,subtype,concept_id,code,name,est_count,is_group,is_selectable,has_attribute,has_hierarchy,path)
select ROW_NUMBER() OVER(order by concept_name) + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as ID,
    (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as parent_id,
    'MEASUREMENT',1,'LOINC','LAB',concept_id,concept_code,concept_name,est_count,0,1,0,1,
    CONCAT( (select path from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where type = 'LOINC' and subtype = 'LAB' and name = 'Uncategorized'), '.',
        CAST(ROW_NUMBER() OVER(order by concept_name) + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) AS STRING) )
from
    (
        select concept_id, concept_code, concept_name, count(distinct person_id) est_count
        from \`$BQ_PROJECT.$BQ_DATASET.measurement\` a
        left join \`$BQ_PROJECT.$BQ_DATASET.concept\` b on a.measurement_concept_id = b.concept_id
        where standard_concept = 'S'
            and domain_id = 'Measurement'
            and vocabulary_id = 'LOINC'
            and measurement_concept_id not in
                (
                    select concept_id
                    from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
                    where type = 'LOINC'
                    and concept_id is not null
                )
        group by 1,2,3
    ) x"

# if loop count above is changed, the number of JOINS below must be updated
echo "MEASUREMENTS - labs - add data into ancestor table"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.prep_criteria_ancestor\`
    (ancestor_id, descendant_id)
select distinct a.ID as ancestor_id,
    coalesce(n.ID, m.ID, k.ID, j.ID, i.ID, h.ID, g.ID, f.ID, e.ID, d.ID, c.ID, b.ID) as descendant_id
from (select id, parent_id, concept_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where type = 'LOINC' and subtype = 'LAB') a
    join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where type = 'LOINC' and subtype = 'LAB') b on a.ID = b.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where type = 'LOINC' and subtype = 'LAB') c on b.ID = c.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where type = 'LOINC' and subtype = 'LAB') d on c.ID = d.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where type = 'LOINC' and subtype = 'LAB') e on d.ID = e.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where type = 'LOINC' and subtype = 'LAB') f on e.ID = f.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where type = 'LOINC' and subtype = 'LAB') g on f.ID = g.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where type = 'LOINC' and subtype = 'LAB') h on g.ID = h.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where type = 'LOINC' and subtype = 'LAB') i on h.ID = i.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where type = 'LOINC' and subtype = 'LAB') j on i.ID = j.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where type = 'LOINC' and subtype = 'LAB') k on j.ID = k.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where type = 'LOINC' and subtype = 'LAB') m on k.ID = m.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where type = 'LOINC' and subtype = 'LAB') n on m.ID = n.PARENT_ID
where a.is_selectable = 0
    and a.parent_id != 0"

echo "MEASUREMENTS - labs - generate parent counts"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"UPDATE \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` x
SET x.est_count = y.cnt
from
    (
        select e.id, count(distinct person_id) cnt
        from
            (
                select * from
                (
                    select id
                    from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
                    where type = 'LOINC'
                        and subtype = 'LAB'
                        and is_group = 1
                        and parent_id != 0
                ) a
                left join \`$BQ_PROJECT.$BQ_DATASET.prep_criteria_ancestor\` b on a.id = b.ancestor_id
            ) e
        left join
            (
                select c.id, d.*
                from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` c
                join
	                (
		                SELECT person_id, concept_id
		                FROM \`$BQ_PROJECT.$BQ_DATASET.measurement\` a
						join
			                (
								select concept_id
								from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
			                	where type = 'LOINC'
									and subtype = 'LAB'
									and is_selectable = 1
			                ) b on a.measurement_concept_id = b.concept_id
	                ) d on c.concept_id = d.concept_id
            ) f on e.descendant_id = f.id
        group by 1
    ) y
where x.id = y.id"


#----- OTHER VOCABULARIES -----
echo "MEASUREMENTS - add other Standard Concepts (except SNOMED)"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,concept_id,code,name,est_count,is_group,is_selectable,has_attribute,has_hierarchy,path)
select ROW_NUMBER() OVER(order by vocabulary_id,concept_name) + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as ID,
    0, 'MEASUREMENT',1, vocabulary_id,concept_id,concept_code,concept_name,est_count,0,1,0,0,
    CAST(ROW_NUMBER() OVER(order by vocabulary_id,concept_name) + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as STRING) as path
from
    (
        select concept_name, vocabulary_id, concept_id, concept_code, count(distinct person_id) est_count
        from \`$BQ_PROJECT.$BQ_DATASET.measurement\` a
        left join \`$BQ_PROJECT.$BQ_DATASET.concept\` b on a.measurement_concept_id = b.concept_id
        where standard_concept = 'S'
            and domain_id = 'Measurement'
            and vocabulary_id not in ('LOINC', 'SNOMED', 'PPI')
        group by 1,2,3,4
    ) x"

#----- SNOMED -----
echo "MEASUREMENTS - SNOMED - temp table level 0"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_meas_in_data\`
    (p_concept_id, p_concept_code, p_concept_name, p_domain_id, concept_id, concept_code, concept_name, domain_id)
select *
from \`$BQ_PROJECT.$BQ_DATASET.v_snomed_rel_meas\` a
where concept_id in
    (
        select distinct measurement_concept_id
        from \`$BQ_PROJECT.$BQ_DATASET.measurement\` a
        left join \`$BQ_PROJECT.$BQ_DATASET.concept\` b on a.measurement_concept_id = b.concept_id
        where measurement_concept_id != 0
            and b.vocabulary_id = 'SNOMED'
            and b.STANDARD_CONCEPT = 'S'
            and b.domain_id = 'Measurement'
    )"

# for each loop, add all items (children/parents) directly under the items that were previously added
# currently, there are only 3 levels, but we run it 4 times to be safe
for i in {1..4};
do
    echo "MEASUREMENTS - SNOMED - temp table level $i"
    bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
    "insert into \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_meas_in_data\`
        (p_concept_id, p_concept_code, p_concept_name, p_domain_id, concept_id, concept_code, concept_name, domain_id)
    select *
    from \`$BQ_PROJECT.$BQ_DATASET.v_snomed_rel_meas\` a
    where concept_id in
        (
            select P_CONCEPT_ID
            from \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_meas_in_data\`
        )
        and concept_id not in
            (
                select CONCEPT_ID
                from \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_meas_in_data\`
            )"
done

echo "MEASUREMENTS - SNOMED - add roots"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,concept_id,code,name,is_group,is_selectable,has_attribute,has_hierarchy,path)
select ROW_NUMBER() OVER(order by concept_name) + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as ID,
    0, 'MEASUREMENT',1,'SNOMED',concept_id,concept_code,concept_name,1,0,0,1,
    CAST(ROW_NUMBER() OVER(order by concept_name) + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as STRING) as path
from
    (
        select distinct concept_id, concept_name, concept_code
        from
            (
                select *, rank() over (partition by descendant_concept_id order by MAX_LEVELS_OF_SEPARATION desc) rnk
                from \`$BQ_PROJECT.$BQ_DATASET.concept_ancestor\` a
                left join \`$BQ_PROJECT.$BQ_DATASET.concept\` b on a.ANCESTOR_CONCEPT_ID = b.concept_id
                where b.domain_id = 'Measurement'
                    and b.vocabulary_id = 'SNOMED'
                    and a.descendant_concept_id in
                        (
                            select distinct concept_id
                            from \`$BQ_PROJECT.$BQ_DATASET.measurement\` a
                            left join \`$BQ_PROJECT.$BQ_DATASET.concept\` b on a.measurement_concept_id = b.concept_id
                            where standard_concept = 'S'
                                and domain_id = 'Measurement'
                                and vocabulary_id = 'SNOMED'
                        )
            ) a
        where rnk = 1
    ) x"

echo "MEASUREMENTS - SNOMED - add level 0"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,concept_id,code,name,is_group,is_selectable,has_attribute,has_hierarchy,path)
select row_number() over (order by p.id, c.concept_name)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`),
    p.id, 'MEASUREMENT',1,'SNOMED',c.concept_id,c.concept_code,c.concept_name,1,0,0,1,
    CONCAT(p.path, '.',
        CAST(row_number() over (order by p.id, c.concept_name)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) AS STRING))
from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` p
join \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_meas_in_data\` c on p.code = c.p_concept_code
where p.domain_id = 'MEASUREMENT'
    and p.type = 'SNOMED'
    and p.id not in
        (
            select parent_id
            from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
        )
    and c.concept_id in
        (
            select p_concept_id
            from \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_meas_in_data\`
        )"

# for each loop, add all items (children/parents) directly under the items that were previously added
# currently, there are only 6 levels, but we run it 7 times to be safe
for i in {1..7};
do
    echo "MEASUREMENTS - SNOMED - add level $i"
    bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
    "insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
        (id,parent_id,domain_id,is_standard,type,concept_id,code,name,is_group,is_selectable,has_attribute,has_hierarchy,path)
    select row_number() over (order by p.id, c.concept_name)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`),
        p.id, 'MEASUREMENT',1,'SNOMED',c.concept_id,c.concept_code,c.concept_name,
        case when l.concept_code is null then 1 else 0 end,
        case when l.concept_code is null then 0 else 1 end,
        0,1,
        CONCAT(p.path, '.',
            CAST(row_number() over (order by p.id, c.concept_name)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as STRING))
    from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` p
    join \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_meas_in_data\` c on p.code = c.p_concept_code
    left join
        (
            select distinct a.concept_code
            from \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_meas_in_data\` a
            left join \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_meas_in_data\` b on a.concept_id = b.p_concept_id
            where b.concept_id is null
        ) l on c.concept_code = l.concept_code
    where p.domain_id = 'MEASUREMENT'
        and p.type = 'SNOMED'
        and p.id not in
            (
                select parent_id
                from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
            )
        and c.concept_id not in
            (
                select parent_id
                from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
            )"
done

echo "MEASUREMENTS - SNOMED - generate counts"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"UPDATE \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` x
SET x.est_count = y.cnt
from
    (
        select ancestor_concept_id as concept_id, count(distinct person_id) cnt
        from
            (
                select *
                from \`$BQ_PROJECT.$BQ_DATASET.concept_ancestor\`
                where ancestor_concept_id in
                    (
                        select distinct concept_id
                        from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
                        where domain_id = 'MEASUREMENT'
                            and type = 'SNOMED'
                    )
            ) a
        join \`$BQ_PROJECT.$BQ_DATASET.measurement\` b on a.descendant_concept_id = b.measurement_concept_id
        group by 1
    ) y
where x.concept_id = y.concept_id
    and x.domain_id = 'MEASUREMENT'
    and x.type = 'SNOMED'"

echo "MEASUREMENTS - SNOMED - add parents as children"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,concept_id,code,name,est_count,is_group,is_selectable,has_attribute,has_hierarchy,path)
select (row_number() over (order by PARENT_ID, NAME)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`)) as ID,
    id as parent_id,domain_id,is_standard,type,concept_id,code,name,cnt,0,1,0,1,CONCAT(path, '.',
    CAST(row_number() over (order by PARENT_ID, NAME)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as STRING))
from
    (
        select *
        from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` a
        join
            (
                select measurement_concept_id, count(distinct person_id) cnt
                from \`$BQ_PROJECT.$BQ_DATASET.measurement\`
                group by 1
            ) b on a.concept_id = b.measurement_concept_id
        where domain_id = 'MEASUREMENT'
            and type = 'SNOMED'
            and is_group = 1
    ) x"


################################################
# DRUG EXPOSURE
################################################
#----- RXNORM / RXNORM EXTENSION -----
echo "DRUGS - temp table - ATC4 to RXNORM"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.atc_rel_in_data\`
    (p_concept_id, p_concept_code, p_concept_name, p_domain_id, concept_id, concept_code, concept_name, domain_id)
select distinct e.p_concept_id, e.p_concept_code, e.p_concept_name, e.p_DOMAIN_ID,
    d.CONCEPT_ID, d.CONCEPT_CODE, d.CONCEPT_NAME, d.DOMAIN_ID
from
    (
        select c1.CONCEPT_ID, c1.CONCEPT_CODE, c1.CONCEPT_NAME, c1.DOMAIN_ID, c2.CONCEPT_ID as atc_5
        from \`$BQ_PROJECT.$BQ_DATASET.concept_relationship\` a
        left join \`$BQ_PROJECT.$BQ_DATASET.concept\` c1 on a.CONCEPT_ID_1 = c1.CONCEPT_ID--parent, rxnorm, ingredient
        left join \`$BQ_PROJECT.$BQ_DATASET.concept\` c2 on a.CONCEPT_ID_2 = c2.CONCEPT_ID--child, atc, atc_5th
        where RELATIONSHIP_ID IN ('RxNorm - ATC name','Mapped from', 'RxNorm - ATC')
            and c1.VOCABULARY_ID = 'RxNorm' and c1.CONCEPT_CLASS_ID = 'Ingredient' and c1.STANDARD_CONCEPT = 'S'
            and c2.VOCABULARY_ID = 'ATC' and c2.CONCEPT_CLASS_ID = 'ATC 5th' and c2.STANDARD_CONCEPT = 'C'
            and c1.concept_id in
                (
                    select ANCESTOR_CONCEPT_ID
                    from \`$BQ_PROJECT.$BQ_DATASET.concept_ancestor\`
                    where DESCENDANT_CONCEPT_ID in
                        (
                            select distinct DRUG_CONCEPT_ID
                            from \`$BQ_PROJECT.$BQ_DATASET.drug_exposure\`
                        )
                )
    ) d
left join
    (
        select c1.CONCEPT_ID as p_concept_id, c1.CONCEPT_CODE as p_concept_code, c1.CONCEPT_NAME as p_concept_name,
            c1.DOMAIN_ID as p_DOMAIN_ID, c2.CONCEPT_ID as atc_5, c2.CONCEPT_CODE, c2.CONCEPT_NAME, c2.DOMAIN_ID
        from \`$BQ_PROJECT.$BQ_DATASET.concept_relationship\` a
        left join \`$BQ_PROJECT.$BQ_DATASET.concept\` c1 on a.CONCEPT_ID_1 = c1.CONCEPT_ID --parent, atc, atc_4
        left join \`$BQ_PROJECT.$BQ_DATASET.concept\` c2 on a.CONCEPT_ID_2 = c2.CONCEPT_ID --child, atc, atc_5
        where RELATIONSHIP_ID = 'Subsumes'
            and c1.VOCABULARY_ID = 'ATC'
            and c1.CONCEPT_CLASS_ID = 'ATC 4th'
            and c1.STANDARD_CONCEPT = 'C'
            and c2.VOCABULARY_ID = 'ATC'
            and c2.CONCEPT_CLASS_ID = 'ATC 5th'
            and c2.STANDARD_CONCEPT = 'C'
    ) e on d.atc_5 = e.atc_5"

echo "DRUGS - temp table - ATC3 to ATC4"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.atc_rel_in_data\`
    (p_concept_id, p_concept_code, p_concept_name, p_domain_id, concept_id, concept_code, concept_name, domain_id)
select c1.CONCEPT_ID as p_concept_id, c1.CONCEPT_CODE as p_concept_code, c1.CONCEPT_NAME as p_concept_name,
    c1.DOMAIN_ID as p_DOMAIN_ID, c2.CONCEPT_ID, c2.CONCEPT_CODE, c2.CONCEPT_NAME, c2.DOMAIN_ID
from \`$BQ_PROJECT.$BQ_DATASET.concept_relationship\` a
    left join \`$BQ_PROJECT.$BQ_DATASET.concept\` c1 on a.CONCEPT_ID_1 = c1.CONCEPT_ID
    left join \`$BQ_PROJECT.$BQ_DATASET.concept\` c2 on a.CONCEPT_ID_2 = c2.CONCEPT_ID
where RELATIONSHIP_ID = 'Subsumes'
    and c1.VOCABULARY_ID = 'ATC' and c1.CONCEPT_CLASS_ID = 'ATC 3rd' and c1.STANDARD_CONCEPT = 'C'
    and c2.VOCABULARY_ID = 'ATC' and c2.CONCEPT_CLASS_ID = 'ATC 4th' and c2.STANDARD_CONCEPT = 'C'
    and c2.concept_id in
        (
            select P_CONCEPT_ID
            from \`$BQ_PROJECT.$BQ_DATASET.atc_rel_in_data\`
        )
    and c2.concept_id not in
        (
            select CONCEPT_ID
            from \`$BQ_PROJECT.$BQ_DATASET.atc_rel_in_data\`
        )"

echo "DRUGS - temp table - ATC2 TO ATC3"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.atc_rel_in_data\`
    (p_concept_id, p_concept_code, p_concept_name, p_domain_id, concept_id, concept_code, concept_name, domain_id)
select c1.CONCEPT_ID as p_concept_id, c1.CONCEPT_CODE as p_concept_code, c1.CONCEPT_NAME as p_concept_name,
    c1.DOMAIN_ID as p_DOMAIN_ID, c2.CONCEPT_ID, c2.CONCEPT_CODE, c2.CONCEPT_NAME, c2.DOMAIN_ID
from \`$BQ_PROJECT.$BQ_DATASET.concept_relationship\` a
left join \`$BQ_PROJECT.$BQ_DATASET.concept\` c1 on a.CONCEPT_ID_1 = c1.CONCEPT_ID
left join \`$BQ_PROJECT.$BQ_DATASET.concept\` c2 on a.CONCEPT_ID_2 = c2.CONCEPT_ID
where RELATIONSHIP_ID = 'Subsumes'
    and c1.VOCABULARY_ID = 'ATC' and c1.CONCEPT_CLASS_ID = 'ATC 2nd' and c1.STANDARD_CONCEPT = 'C'
    and c2.VOCABULARY_ID = 'ATC' and c2.CONCEPT_CLASS_ID = 'ATC 3rd' and c2.STANDARD_CONCEPT = 'C'
    and c2.concept_id in
        (
            select P_CONCEPT_ID
            from \`$BQ_PROJECT.$BQ_DATASET.atc_rel_in_data\`
        )
    and c2.concept_id not in
        (
            select CONCEPT_ID
            from \`$BQ_PROJECT.$BQ_DATASET.atc_rel_in_data\`
        )"

echo "DRUGS - temp table - ATC1 TO ATC2"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.atc_rel_in_data\`
    (p_concept_id, p_concept_code, p_concept_name, p_domain_id, concept_id, concept_code, concept_name, domain_id)
select c1.CONCEPT_ID as p_concept_id, c1.CONCEPT_CODE as p_concept_code, c1.CONCEPT_NAME as p_concept_name,
    c1.DOMAIN_ID as p_DOMAIN_ID, c2.CONCEPT_ID, c2.CONCEPT_CODE, c2.CONCEPT_NAME, c2.DOMAIN_ID
from \`$BQ_PROJECT.$BQ_DATASET.concept_relationship\` a
left join \`$BQ_PROJECT.$BQ_DATASET.concept\` c1 on a.CONCEPT_ID_1 = c1.CONCEPT_ID
left join \`$BQ_PROJECT.$BQ_DATASET.concept\` c2 on a.CONCEPT_ID_2 = c2.CONCEPT_ID
where RELATIONSHIP_ID = 'Subsumes'
    and c1.VOCABULARY_ID = 'ATC' and c1.CONCEPT_CLASS_ID = 'ATC 1st' and c1.STANDARD_CONCEPT = 'C'
    and c2.VOCABULARY_ID = 'ATC' and c2.CONCEPT_CLASS_ID = 'ATC 2nd' and c2.STANDARD_CONCEPT = 'C'
    and c2.concept_id in
        (
            select P_CONCEPT_ID
            from \`$BQ_PROJECT.$BQ_DATASET.atc_rel_in_data\`
        )
    and c2.concept_id not in
        (
            select CONCEPT_ID
            from \`$BQ_PROJECT.$BQ_DATASET.atc_rel_in_data\`
        )"

echo "DRUGS - add roots"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,concept_id,code,name,is_group,is_selectable,has_attribute,has_hierarchy,has_ancestor_data,path)
select row_number() over (order by concept_code) + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) AS ID,
    0, 'DRUG', 1, 'ATC', concept_id, concept_code, CONCAT( UPPER(SUBSTR(concept_name, 1, 1)), LOWER(SUBSTR(concept_name, 2)) ),
    1,0,0,1,1,
    CAST(ROW_NUMBER() OVER(order by concept_code) + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as STRING) as path
from \`$BQ_PROJECT.$BQ_DATASET.concept\`
where VOCABULARY_ID = 'ATC'
    and CONCEPT_CLASS_ID = 'ATC 1st'
    and STANDARD_CONCEPT = 'C'"

echo "DRUGS - add root for unmapped ingredients"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,name,is_group,is_selectable,has_attribute,has_hierarchy,has_ancestor_data,path)
select (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`)+1 AS ID,
    0,'DRUG',1,'ATC','Unmapped ingredients',1,0,0,1,1,
    CAST( (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`)+1 as STRING ) as path"

echo "DRUGS - level 2"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,concept_id,code,name,is_group,is_selectable,has_attribute,has_hierarchy,has_ancestor_data,path)
select row_number() over (order by p.id, c.concept_code)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`),
    p.id,'DRUG',1,'ATC',c.concept_id,c.concept_code,
    CONCAT( UPPER(SUBSTR(c.concept_name, 1, 1)), LOWER(SUBSTR(c.concept_name, 2)) ),1,1,0,1,1,
    CONCAT(p.path, '.',
        CAST(row_number() over (order by p.id, c.concept_code)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as STRING))
from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` p
join \`$BQ_PROJECT.$BQ_DATASET.atc_rel_in_data\` c on p.code = c.p_concept_code
where p.domain_id = 'DRUG'
    and p.type = 'ATC'
    and p.id not in
        (
            select parent_id
            from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
            where domain_id = 'DRUG'
                and type = 'ATC'
        )"

echo "DRUGS - level 3"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,concept_id,code,name,is_group,is_selectable,has_attribute,has_hierarchy,has_ancestor_data,path)
select row_number() over (order by p.id, c.concept_code)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`),
    p.id,'DRUG',1,'ATC',c.concept_id,c.concept_code,
    CONCAT( UPPER(SUBSTR(c.concept_name, 1, 1)), LOWER(SUBSTR(c.concept_name, 2)) ),1,1,0,1,1,
    CONCAT(p.path, '.',
        CAST(row_number() over (order by p.id, c.concept_code)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as STRING))
from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` p
join \`$BQ_PROJECT.$BQ_DATASET.atc_rel_in_data\` c on p.code = c.p_concept_code
where p.domain_id = 'DRUG'
    and p.type = 'ATC'
    and p.id not in
        (
            select parent_id
            from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
            where domain_id = 'DRUG'
                and type = 'ATC'
        )"

echo "DRUGS - level 4"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,concept_id,code,name,is_group,is_selectable,has_attribute,has_hierarchy,has_ancestor_data,path)
select row_number() over (order by p.id, c.concept_code)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`),
    p.id,'DRUG',1,'ATC',c.concept_id,c.concept_code,
    CONCAT( UPPER(SUBSTR(c.concept_name, 1, 1)), LOWER(SUBSTR(c.concept_name, 2)) ),1,1,0,1,1,
    CONCAT(p.path, '.',
        CAST(row_number() over (order by p.id, c.concept_code)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as STRING))
from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` p
join \`$BQ_PROJECT.$BQ_DATASET.atc_rel_in_data\` c on p.code = c.p_concept_code
where p.domain_id = 'DRUG'
    and p.type = 'ATC'
    and p.id not in
        (
            select parent_id
            from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
            where domain_id = 'DRUG'
                and type = 'ATC'
        )"

echo "DRUGS - level 5 - ingredients"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,concept_id,code,name,is_group,is_selectable,has_attribute,has_hierarchy,has_ancestor_data,path)
select row_number() over (order by p.id, UPPER(c.concept_name))+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`),
    p.id,'DRUG',1,'RXNORM',c.concept_id,c.concept_code,
    CONCAT( UPPER(SUBSTR(c.concept_name, 1, 1)), LOWER(SUBSTR(c.concept_name, 2)) ),0,1,0,1,1,
    CONCAT(p.path, '.',
        CAST(row_number() over (order by p.id, UPPER(c.concept_name))+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as STRING))
from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` p
join \`$BQ_PROJECT.$BQ_DATASET.atc_rel_in_data\` c on p.code = c.p_concept_code
where p.domain_id = 'DRUG'
    and p.type = 'ATC'
    and p.id not in
        (
            select parent_id
            from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
            where domain_id = 'DRUG'
                and type = 'ATC'
        )"

echo "DRUGS - add parents for unmapped ingredients"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,code,name,is_group,is_selectable,has_attribute,has_hierarchy,has_ancestor_data,path)
select ROW_NUMBER() OVER(ORDER BY upper(name)) + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) AS ID,
    (select id from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`  where name = 'Unmapped ingredients') as parent_id,
    'DRUG',1,'ATC',name as code, name,1,0,0,1,1,
    CONCAT( (select CAST(id as STRING) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`  where name = 'Unmapped ingredients'),
        '.', CAST(ROW_NUMBER() OVER(ORDER BY upper(name)) + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) AS STRING) )
from
    (
        select distinct UPPER(SUBSTR(concept_name, 1, 1)) name
        from \`$BQ_PROJECT.$BQ_DATASET.concept\`
        where VOCABULARY_ID = 'RxNorm'
            and CONCEPT_CLASS_ID = 'Ingredient'
            and STANDARD_CONCEPT = 'S'
            and concept_id in
                (
                    select ANCESTOR_CONCEPT_ID
                    from \`$BQ_PROJECT.$BQ_DATASET.concept_ancestor\`
                    where DESCENDANT_CONCEPT_ID in
                        (
                            select distinct DRUG_CONCEPT_ID
                            from \`$BQ_PROJECT.$BQ_DATASET.drug_exposure\`
                        )
                )
            and concept_id not in
                (
                    select concept_id
                    from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
                    where domain_id = 'DRUG'
                        and type = 'RXNORM'
                )

    ) x"

echo "DRUGS - add unmapped ingredients"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,concept_id,code,name,is_group,is_selectable,has_attribute,has_hierarchy,has_ancestor_data,path)
select row_number() over (order by z.id, upper(x.concept_name))+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`),
    z.id,'DRUG',1,'RXNORM',x.concept_id,x.concept_code,CONCAT( UPPER(SUBSTR(x.concept_name, 1, 1)), LOWER(SUBSTR(x.concept_name, 2)) ),
    0,1,0,1,1,
    CONCAT(z.path, '.',
        CAST(ROW_NUMBER() OVER(order by z.id, upper(x.concept_name)) + (SELECT MAX(id) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) AS STRING))
from
    (
        select *
        from \`$BQ_PROJECT.$BQ_DATASET.concept\`
        where VOCABULARY_ID = 'RxNorm'
            and CONCEPT_CLASS_ID = 'Ingredient'
            and STANDARD_CONCEPT = 'S'
            and concept_id in
                (
                    select ANCESTOR_CONCEPT_ID
                    from \`$BQ_PROJECT.$BQ_DATASET.concept_ancestor\`
                    where DESCENDANT_CONCEPT_ID in
                        (
                            select distinct DRUG_CONCEPT_ID
                            from \`$BQ_PROJECT.$BQ_DATASET.drug_exposure\`
                        )
                )
            and concept_id not in
                (
                    select concept_id
                    from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
                    where domain_id = 'DRUG'
                        and type = 'RXNORM'
                )
    ) x
join
    (
        select *
        from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
        where domain_id = 'DRUG'
            and type = 'ATC'
            and length(name) = 1
    ) z on UPPER(SUBSTR(x.concept_name, 1, 1)) = z.name"

echo "DRUGS - generate child counts"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"update \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` x
set x.est_count = y.cnt
from
    (
        select b.ANCESTOR_CONCEPT_ID as concept_id, count(distinct a.person_id) cnt
        from \`$BQ_PROJECT.$BQ_DATASET.drug_exposure\` a
        join
            (
                select *
                from \`$BQ_PROJECT.$BQ_DATASET.concept_ancestor\` x
                left join \`$BQ_PROJECT.$BQ_DATASET.concept\` y on x.ANCESTOR_CONCEPT_ID = y.CONCEPT_ID
                where VOCABULARY_ID = 'RxNorm'
                    and CONCEPT_CLASS_ID = 'Ingredient'
            ) b on a.DRUG_CONCEPT_ID = b.DESCENDANT_CONCEPT_ID
        group by 1
    ) y
where x.concept_id = y.concept_id
    and x.domain_id = 'DRUG'
    and x.type = 'RXNORM'"

echo "DRUGS - add brand names"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,concept_id,code,name,is_group,is_selectable,has_attribute,has_hierarchy)
select ROW_NUMBER() OVER(ORDER BY upper(concept_name)) + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) AS ID,
    0,'DRUG',1,'BRAND',concept_id,concept_code,concept_name,0,1,0,0
FROM
    (
        select distinct b.concept_id, b.concept_name, b.concept_code
        from \`$BQ_PROJECT.$BQ_DATASET.concept_relationship\` a
        left join \`$BQ_PROJECT.$BQ_DATASET.concept\` b on a.CONCEPT_ID_1 = b.CONCEPT_ID --brands
        left join \`$BQ_PROJECT.$BQ_DATASET.concept\` c on a.CONCEPT_ID_2 = c.CONCEPT_ID --ingredients
        where b.vocabulary_id in ('RxNorm','RxNorm Extension')
            and b.concept_class_id = 'Brand Name'
            and b.invalid_reason is null
            and c.concept_id in
                (
                    select concept_id
                    from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
                    where domain_id = 'DRUG'
                        and type = 'RXNORM'
                        and is_group = 0
                        and is_selectable = 1
                )
    ) x"

echo "DRUGS - add data into prep_criteria_ancestor table"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.prep_criteria_ancestor\`
    (ancestor_id, descendant_id)
select distinct a.ID as ancestor_id,
    coalesce(e.ID, d.ID, c.ID, b.ID) as descendant_id
from (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'DRUG' and type in ('ATC','RXNORM')) a
join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'DRUG' and type in ('ATC','RXNORM')) b on a.ID = b.PARENT_ID
left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'DRUG' and type in ('ATC','RXNORM')) c on b.ID = c.PARENT_ID
left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'DRUG' and type in ('ATC','RXNORM')) d on c.ID = d.PARENT_ID
left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'DRUG' and type in ('ATC','RXNORM')) e on d.ID = e.PARENT_ID
where a.is_group = 1
    and a.is_selectable = 1"

echo "DRUGS - generate parent counts"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"UPDATE \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` x
SET x.est_count = y.cnt
from
    (
        select g.id, count(distinct person_id) cnt
        from
            (
                select *
                from
                    (
                        select id
                        from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
                        where domain_id = 'DRUG'
                            and type = 'ATC'
                            and is_group = 1
                            and is_selectable = 1
                    ) a
                    left join \`$BQ_PROJECT.$BQ_DATASET.prep_criteria_ancestor\` b on a.id = b.ancestor_id
            ) g
        left join
            (
                select e.id, f.*
                from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` e
                join
                    (
                        select d.ANCESTOR_CONCEPT_ID as concept_id, c.person_id
                        from \`$BQ_PROJECT.$BQ_DATASET.drug_exposure\` c
                        join
                            (
                                select *
                                from \`$BQ_PROJECT.$BQ_DATASET.concept_ancestor\` a
                                left join \`$BQ_PROJECT.$BQ_DATASET.concept\` b on a.ANCESTOR_CONCEPT_ID = b.CONCEPT_ID
                                where VOCABULARY_ID = 'RxNorm'
                                    and CONCEPT_CLASS_ID = 'Ingredient'
                            ) d on c.DRUG_CONCEPT_ID = d.DESCENDANT_CONCEPT_ID
                    ) f on e.concept_id = f.concept_id
            ) h on g.descendant_id = h.id
        group by 1
    ) y
where x.id = y.id"


#----- OTHER VOCABULARIES -----
echo "DRUGS - add other Standard Concepts"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,concept_id,code,name,est_count,is_group,is_selectable,has_attribute,has_hierarchy,path)
select ROW_NUMBER() OVER(order by vocabulary_id,concept_name) + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as ID,
    0, 'DRUG',1, vocabulary_id,concept_id,concept_code,concept_name,est_count,0,1,0,0,
    CAST(ROW_NUMBER() OVER(order by vocabulary_id,concept_name) + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as STRING) as path
from
    (
        select concept_name, vocabulary_id, concept_id, concept_code, count(distinct person_id) est_count
        from \`$BQ_PROJECT.$BQ_DATASET.drug_exposure\` a
        left join \`$BQ_PROJECT.$BQ_DATASET.concept\` b on a.drug_concept_id = b.concept_id
        where standard_concept = 'S'
            and domain_id = 'Drug'
            and vocabulary_id not in ('RxNorm','RxNorm Extension')
        group by 1,2,3,4
    ) x"


################################################
# PROCEDURES
################################################
#----- STANDARD SNOMED -----
echo "PROCEDURES - STANDARD SNOMED - temp table level 0"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_pcs_in_data\`
    (p_concept_id, p_concept_code, p_concept_name, p_domain_id, concept_id, concept_code, concept_name, domain_id)
select *
from \`$BQ_PROJECT.$BQ_DATASET.v_snomed_rel_pcs\` a
where concept_id in
    (
        select distinct procedure_concept_id
        from \`$BQ_PROJECT.$BQ_DATASET.procedure_occurrence\` a
        left join \`$BQ_PROJECT.$BQ_DATASET.concept\` b on a.procedure_concept_id = b.concept_id
        where procedure_concept_id != 0
            and b.domain_id = 'Procedure'
            and b.vocabulary_id = 'SNOMED'
            and b.standard_concept = 'S'
    )"

# currently, there are only 8 levels, but we run it 9 times to be safe
for i in {1..9};
do
    echo "PROCEDURES - STANDARD SNOMED - temp table level $i"
    bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
    "insert into \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_pcs_in_data\`
        (p_concept_id, p_concept_code, p_concept_name, p_domain_id, concept_id, concept_code, concept_name, domain_id)
    select *
    from \`$BQ_PROJECT.$BQ_DATASET.v_snomed_rel_pcs\` a
    where
        concept_id in
            (
                select P_CONCEPT_ID
                from \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_pcs_in_data\`
            )
        and concept_id not in
            (
                select CONCEPT_ID
                from \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_pcs_in_data\`
            )"
done

echo "PROCEDURES - STANDARD SNOMED - add root"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,concept_id,code,name,is_group,is_selectable,has_attribute,has_hierarchy,path)
select (select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`)+1,
    0,'PROCEDURE',1,'SNOMED',concept_id,concept_code,concept_name,1,0,0,1,
    CAST((SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`)+1 as STRING) as path
from \`$BQ_PROJECT.$BQ_DATASET.concept\`
where concept_id = 4322976"

echo "PROCEDURES - STANDARD SNOMED - add level 0"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,concept_id,code,name,is_group,is_selectable,has_attribute,has_hierarchy,path)
select row_number() over (order by p.id, c.concept_name)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`),
    p.id,'PROCEDURE',1,'SNOMED',c.concept_id,c.concept_code,c.concept_name,1,1,0,1,
    CONCAT(p.path, '.',
        CAST(row_number() over (order by p.id, c.concept_name)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) AS STRING))
from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` p
join \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_pcs_in_data\` c on p.code = c.p_concept_code
where p.domain_id = 'PROCEDURE'
    and p.type = 'SNOMED'
    and p.is_standard = 1
    and p.id not in
        (
            select parent_id
            from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
        )
    and c.concept_id in
        (
            select p_concept_id
            from \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_pcs_in_data\`
        )"

# currently, there are only 11 levels, but we run it 12 times to be safe
for i in {1..12};
do
    echo "PROCEDURES - STANDARD SNOMED - add level $i"
    bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
    "insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
        (id,parent_id,domain_id,is_standard,type,concept_id,code,name,is_group,is_selectable,has_attribute,has_hierarchy,path)
    select row_number() over (order by p.id, c.concept_name)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`),
        p.id,'PROCEDURE',1,'SNOMED',c.concept_id,c.concept_code,c.concept_name,
        case when l.concept_code is null then 1 else 0 end,
        1,0,1,
        CONCAT(p.path, '.',
            CAST(row_number() over (order by p.id, c.concept_name)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as STRING))
    from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` p
    join \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_pcs_in_data\` c on p.code = c.p_concept_code
    left join
        (
            select distinct a.CONCEPT_CODE
            from \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_pcs_in_data\` a
            left join \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_pcs_in_data\` b on a.concept_id = b.p_concept_id
            where b.concept_id is null
        ) l on c.concept_code = l.concept_code
    where p.domain_id = 'PROCEDURE'
        and p.type = 'SNOMED'
        and p.is_standard = 1
        and p.id not in
            (
                select PARENT_ID
                from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
            )"
done

echo "PROCEDURES - STANDARD SNOMED - generate child counts"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"update \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` x
set x.est_count = y.cnt
from
    (
        SELECT procedure_concept_id as concept_id, count(distinct person_id) cnt
        FROM \`$BQ_PROJECT.$BQ_DATASET.procedure_occurrence\`
        GROUP BY 1
    ) y
where x.concept_id = y.concept_id
    and x.domain_id = 'PROCEDURE'
    and x.type = 'SNOMED'
    and x.is_standard = 1
    and x.is_group = 0
    and x.is_selectable = 1"

echo "PROCEDURES - STANDARD SNOMED - generate parent counts"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"UPDATE \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` x
SET x.est_count = y.cnt
from
    (
        select ancestor_concept_id as concept_id, count(distinct person_id) cnt
        from
            (
                select *
                from \`$BQ_PROJECT.$BQ_DATASET.concept_ancestor\`
                where ancestor_concept_id in
                    (
                        select distinct concept_id
                        from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
                        where domain_id = 'PROCEDURE'
                            and type = 'SNOMED'
                            and is_standard = 1
                            and parent_id != 0
                            and is_group = 1
                    )
            ) a
        join \`$BQ_PROJECT.$BQ_DATASET.procedure_occurrence\` b on a.descendant_concept_id = b.procedure_concept_id
        group by 1
    ) y
where x.concept_id = y.concept_id
    and x.domain_id = 'PROCEDURE'
    and x.type = 'SNOMED'
    and x.is_standard = 1
    and x.is_group = 1"


#----- OTHER STANDARD VOCABULARIES -----
echo "PROCEDURES - add other Standard Concepts"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,concept_id,code,name,est_count,is_group,is_selectable,has_attribute,has_hierarchy,path)
select ROW_NUMBER() OVER(order by vocabulary_id,concept_name) + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as ID,
    0, 'PROCEDURE',1, vocabulary_id,concept_id,concept_code,concept_name,est_count,0,1,0,0,
    CAST(ROW_NUMBER() OVER(order by vocabulary_id,concept_name) + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as STRING) as path
from
    (
        select concept_name, vocabulary_id, concept_id, concept_code, count(distinct person_id) est_count
        from \`$BQ_PROJECT.$BQ_DATASET.procedure_occurrence\` a
        left join \`$BQ_PROJECT.$BQ_DATASET.concept\` b on a.procedure_concept_id = b.concept_id
        where standard_concept = 'S'
            and domain_id = 'Procedure'
            and vocabulary_id not in ('SNOMED')
        group by 1,2,3,4
    ) x"


# ----- SOURCE SNOMED -----
echo "PROCEDURES - SOURCE SNOMED - temp table level 0"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_pcs_src_in_data\`
    (p_concept_id, p_concept_code, p_concept_name, p_domain_id, concept_id, concept_code, concept_name, domain_id)
select *
from \`$BQ_PROJECT.$BQ_DATASET.v_snomed_rel_pcs_src\` a
where concept_id in
    (
        select distinct procedure_source_concept_id
        from \`$BQ_PROJECT.$BQ_DATASET.procedure_occurrence\` a
        left join \`$BQ_PROJECT.$BQ_DATASET.concept\` b on a.procedure_source_concept_id = b.concept_id
        where procedure_source_concept_id != 0
            and b.domain_id = 'Procedure'
            and b.vocabulary_id = 'SNOMED'
    )"

# currently, there are only 8 levels, but we run it 9 times to be safe
for i in {1..9};
do
    echo "PROCEDURES - SOURCE SNOMED - temp table level $i"
    bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
    "insert into \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_pcs_src_in_data\`
        (p_concept_id, p_concept_code, p_concept_name, p_domain_id, concept_id, concept_code, concept_name, domain_id)
    select *
    from \`$BQ_PROJECT.$BQ_DATASET.v_snomed_rel_pcs_src\` a
    where concept_id in
        (
            select P_CONCEPT_ID
            from \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_pcs_src_in_data\`
        )
        and concept_id not in
            (
                select CONCEPT_ID
                from \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_pcs_src_in_data\`
            )"
done

echo "PROCEDURES - SOURCE SNOMED - add root"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,concept_id,code,name,is_group,is_selectable,has_attribute,has_hierarchy,path)
select (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`)+1 AS ID,
    0,'PROCEDURE',0,'SNOMED',concept_id,concept_code,concept_name,1,0,0,1,
    CAST((SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`)+1 as STRING) as path
from \`$BQ_PROJECT.$BQ_DATASET.concept\`
where concept_id = 4322976"

echo "PROCEDURES - SOURCE SNOMED - add level 0"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,concept_id,code,name,is_group,is_selectable,has_attribute,has_hierarchy,path)
select row_number() over (order by p.id, c.concept_name)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`),
    p.id,'PROCEDURE',0,'SNOMED',c.concept_id,c.concept_code,c.concept_name,1,1,0,1,
    CONCAT(p.path, '.',
        CAST(row_number() over (order by p.id, c.concept_name)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) AS STRING))
from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` p
join \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_pcs_src_in_data\` c on p.code = c.p_concept_code
where p.domain_id = 'PROCEDURE'
    and p.type = 'SNOMED'
    and p.is_standard = 0
    and p.id not in
        (
            select parent_id
            from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
        )
    and c.concept_id in
        (
            select p_concept_id
            from \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_pcs_src_in_data\`
        )"

# currently, there are only 11 levels, but we run it 12 times to be safe (if changed, change number of joins in next query)
for i in {1..12};
do
    echo "PROCEDURES - SOURCE SNOMED - add level $i"
    bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
    "insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
        (id,parent_id,domain_id,is_standard,type,concept_id,code,name,is_group,is_selectable,has_attribute,has_hierarchy,path)
    select row_number() over (order by p.id, c.concept_name)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`),
        p.id,'PROCEDURE',0,'SNOMED',c.concept_id,c.concept_code,c.concept_name,
        case when l.concept_code is null then 1 else 0 end,
        1,0,1,
        CONCAT(p.path, '.',
            CAST(row_number() over (order by p.id, c.concept_name)+(select max(id) from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as STRING))
    from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` p
    join \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_pcs_src_in_data\` c on p.code = c.p_concept_code
    left join
        (
            select distinct a.concept_code
            from \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_pcs_src_in_data\` a
            left join \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_pcs_src_in_data\` b on a.concept_id = b.p_concept_id
            where b.concept_id is null
        ) l on c.concept_code = l.concept_code
    where p.domain_id = 'PROCEDURE'
        and p.type = 'SNOMED'
        and p.is_standard = 0
        and p.id not in
            (
                select parent_id
                from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
            )"
done

# if loop count above is changed, the number of JOINS below must be updated
echo "PROCEDURES - SOURCE SNOMED - add data into ancestor table"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.prep_criteria_ancestor\` (ancestor_id, descendant_id)
select distinct a.ID as ancestor_id,
    coalesce(n.ID, m.ID, k.ID, j.ID, i.ID, h.ID, g.ID, f.ID, e.ID, d.ID, c.ID, b.ID) as descendant_id
from (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'PROCEDURE' and type = 'SNOMED' and is_standard = 0) a
    join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'PROCEDURE' and type = 'SNOMED' and is_standard = 0) b on a.ID = b.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'PROCEDURE' and type = 'SNOMED' and is_standard = 0) c on b.ID = c.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'PROCEDURE' and type = 'SNOMED' and is_standard = 0) d on c.ID = d.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'PROCEDURE' and type = 'SNOMED' and is_standard = 0) e on d.ID = e.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'PROCEDURE' and type = 'SNOMED' and is_standard = 0) f on e.ID = f.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'PROCEDURE' and type = 'SNOMED' and is_standard = 0) g on f.ID = g.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'PROCEDURE' and type = 'SNOMED' and is_standard = 0) h on g.ID = h.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'PROCEDURE' and type = 'SNOMED' and is_standard = 0) i on h.ID = i.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'PROCEDURE' and type = 'SNOMED' and is_standard = 0) j on i.ID = j.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'PROCEDURE' and type = 'SNOMED' and is_standard = 0) k on j.ID = k.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'PROCEDURE' and type = 'SNOMED' and is_standard = 0) m on k.ID = m.PARENT_ID
    left join (select id, parent_id, is_group, is_selectable from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` where domain_id = 'PROCEDURE' and type = 'SNOMED' and is_standard = 0) n on m.ID = n.PARENT_ID
where a.parent_id != 0 and a.is_group = 1"

echo "PROCEDURES - SOURCE SNOMED - child counts"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"update \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` x
set x.est_count = y.cnt
from
    (
        select procedure_source_concept_id as concept_id, count(distinct person_id) cnt
        from \`$BQ_PROJECT.$BQ_DATASET.procedure_occurrence\`
        group by 1
    ) y
where x.concept_id = y.concept_id
    and x.domain_id = 'PROCEDURE'
    and x.type = 'SNOMED'
    and x.is_standard = 0
    and x.is_group = 0
    and x.is_selectable = 1"

echo "PROCEDURES - SOURCE SNOMED - parent counts"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"UPDATE \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` x
SET x.est_count = y.cnt
from
    (
        select e.id, count(distinct person_id) cnt
        from
            (
                select *
                from
                    (
                        select id
                        from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
                        where domain_id = 'PROCEDURE'
                            and type = 'SNOMED'
                            and is_standard = 0
                            and parent_id != 0
                            and is_group = 1
                    ) a
                left join \`$BQ_PROJECT.$BQ_DATASET.prep_criteria_ancestor\` b on a.id = b.ancestor_id
            ) e
        left join
            (
                select c.id, d.*
                from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` c
                join
                    (
                        select a.person_id, a.procedure_source_concept_id as concept_id
                        from \`$BQ_PROJECT.$BQ_DATASET.procedure_occurrence\` a
                        join
                            (
                                select concept_id, path
                                from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
                                where domain_id = 'PROCEDURE'
                                    and type = 'SNOMED'
                                    and is_standard = 0
                                    and is_group = 0
                                    and is_selectable = 1
                            ) b on a.procedure_source_concept_id = b.concept_id
                    ) d on c.concept_id = d.concept_id
            ) f on e.descendant_id = f.id
        group by 1
    ) y
where x.id = y.id"


#----- HCPCS -----
echo "PROCEDURES - SOURCE - HCPCS"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
    (id,parent_id,domain_id,is_standard,type,concept_id,code,name,est_count,is_group,is_selectable,has_attribute,has_hierarchy,path)
select ROW_NUMBER() OVER(order by vocabulary_id,concept_name) + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as ID,
    0, 'PROCEDURE',0, vocabulary_id,concept_id,concept_code,concept_name,est_count,0,1,0,0,
    CAST(ROW_NUMBER() OVER(order by vocabulary_id,concept_name) + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`) as STRING) as path
from
    (
        select concept_name, vocabulary_id, concept_id, concept_code, count(distinct person_id) est_count
        from \`$BQ_PROJECT.$BQ_DATASET.procedure_occurrence\` a
        left join \`$BQ_PROJECT.$BQ_DATASET.concept\` b on a.procedure_source_concept_id = b.concept_id
        where domain_id = 'Procedure'
            and vocabulary_id in ('HCPCS')
        group by 1,2,3,4
    ) x"


################################################
# CB_CRITERIA ANCESTOR
################################################
echo "CB_CRITERIA_ANCESTOR - Drugs - add ingredients to drugs mapping"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria_ancestor\`
    (ancestor_id, descendant_id)
select ancestor_concept_id, descendant_concept_id
from \`$BQ_PROJECT.$BQ_DATASET.concept_ancestor\`
where ancestor_concept_id in
    (
        select distinct concept_id
        from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
        where domain_id = 'DRUG'
            and type = 'RXNORM'
            and is_group = 0
            and is_selectable = 1
    )
and descendant_concept_id in
    (
        select distinct drug_concept_id
        from \`$BQ_PROJECT.$BQ_DATASET.drug_exposure\`
    )"


################################################
# CB_CRITERIA_ATTRIBUTE
################################################
# this code filters out any labs where all results = 0
echo "CB_CRITERIA_ATTRIBUTE - Measurements - add numeric results"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria_attribute\`
    (id, concept_id, value_as_concept_id, concept_name, type, est_count)
select ROW_NUMBER() OVER(order by measurement_concept_id), *
from
	(
		select measurement_concept_id, 0, 'MIN', 'NUM', CAST(min(value_as_number) as STRING)
		from \`$BQ_PROJECT.$BQ_DATASET.measurement\`
		where measurement_concept_id in
			(
				select concept_id
				from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
				where domain_id = 'MEASUREMENT'
			)
			and value_as_number is not null
		group by 1
		having not (min(value_as_number) = 0 and max(value_as_number) = 0)

		UNION ALL

		select measurement_concept_id, 0, 'MAX', 'NUM', CAST(max(value_as_number) as STRING)
		from \`$BQ_PROJECT.$BQ_DATASET.measurement\`
		where measurement_concept_id in
			(
				select concept_id
				from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
				where domain_id = 'MEASUREMENT'
			)
			and value_as_number is not null
		group by 1
		having not (min(value_as_number) = 0 and max(value_as_number) = 0)
	) a"

echo "CB_CRITERIA_ATTRIBUTE - Measurements - add categorical results"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria_attribute\`
    (id, concept_id, value_as_concept_Id, concept_name, type, est_count)
select ROW_NUMBER() OVER(order by measurement_concept_id) + (SELECT MAX(ID) FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria_attribute\`) as id, *
from
    (
        select measurement_concept_id, value_as_concept_id, b.concept_name, 'CAT' as type, CAST(count(distinct person_id) as STRING)
        from \`$BQ_PROJECT.$BQ_DATASET.measurement\` a
        left join \`$BQ_PROJECT.$BQ_DATASET.concept\` b on a.value_as_concept_Id = b.concept_id
        where measurement_concept_id in
            (
                select concept_id
                from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
                where domain_id = 'MEASUREMENT'
            )
            and value_as_concept_id != 0
            and value_as_concept_id is not null
        group by 1,2,3
    ) a"

# set has_attributes=1 for any criteria that has data in cb_criteria_attribute
echo "CB_CRITERIA_ATTRIBUTE - update has_attributes column for measurement criteria"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"update \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
set has_attribute = 1
where concept_id in
    (
        select distinct concept_id
        from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria_attribute\`
    )
    and domain_id = 'MEASUREMENT'
    and is_selectable = 1"


################################################
# CB_CRITERIA_RELATIONSHIP
################################################
echo "CB_CRITERIA_RELATIONSHIP - Drugs - add drug/ingredient relationships"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria_relationship\`
    (concept_id_1, concept_id_2)
select a.concept_id_1, a.concept_id_2
from \`$BQ_PROJECT.$BQ_DATASET.concept_relationship\` a
join \`$BQ_PROJECT.$BQ_DATASET.concept\` b on a.concept_id_2 = b.concept_id
where b.concept_class_id = 'Ingredient'
    and a.concept_id_1 in
        (
            select concept_id
            from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
            where domain_id = 'DRUG'
                and type = 'BRAND'
        )"

echo "CB_CRITERIA_RELATIONSHIP - Source Concept -> Standard Concept Mapping"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"insert into \`$BQ_PROJECT.$BQ_DATASET.cb_criteria_relationship\`
    (concept_id_1, concept_id_2)
SELECT a.concept_id_1 as source_concept_id, a.concept_id_2 as standard_concept_id
FROM \`$BQ_PROJECT.$BQ_DATASET.concept_relationship\` a
JOIN \`$BQ_PROJECT.$BQ_DATASET.concept\` b on a.concept_id_2 = b.concept_id
WHERE b.standard_concept = 'S'
    AND a.relationship_id = 'Maps to'
    AND a.concept_id_1 in
        (
            SELECT DISTINCT concept_id
            FROM \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
            WHERE concept_id is not null
                and is_standard = 0
        )"


################################################
# DATA CLEAN UP
################################################
echo "CLEAN UP - set est_count = -1 where the count is NULL"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"UPDATE \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
set est_count = -1
where est_count is null"

echo "CLEAN UP - set has_ancestor_data = 0 for all items where it is currently NULL"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"UPDATE \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
set has_ancestor_data = 0
where has_ancestor_data is null"

echo "CLEAN UP - remove all double quotes from criteria names"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"UPDATE \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
SET name = REGEXP_REPLACE(name, r'[\"]', '')
WHERE REGEXP_CONTAINS(name, r'[\"]')"


################################################
# SYNONYMS
################################################
echo "SYNONYMS - add synonym data to criteria"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"update \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` x
set x.synonyms = y.synonyms
from
    (
        select c.id,
        case
            when c.name is not null and string_agg(replace(cs.concept_synonym_name,'|','||'),'|') is null then c.name
            else concat(c.name,'|',string_agg(replace(cs.concept_synonym_name,'|','||'),'|'))
        end as synonyms
        from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` c
        left join \`$BQ_PROJECT.$BQ_DATASET.concept_synonym\` cs on c.concept_id = cs.concept_id
        where domain_id not in ('SURVEY', 'PERSON')
        group by c.id, c.name, c.code
    ) y
where x.id = y.id"

echo "SYNONYMS - add demographics synonym data"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"update \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` x
set x.synonyms = y.synonyms
from
    (
        select id,
        case
            when type = 'AGE' and parent_id = 0 then 'Age'
            when type = 'DECEASED' and parent_id = 0 then 'Deceased'
            when type = 'GENDER' and parent_id = 0 then 'Gender'
            when type = 'RACE' and parent_id = 0 then 'Race'
            when type = 'ETHNICITY' and parent_id = 0 then 'Ethnicity'
            when type = 'AGE' and parent_id != 0 then null
        else name
        end as synonyms
        from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
        where domain_id = 'PERSON'
    ) y
where x.id = y.id"

echo "SYNONYMS - add PPI synonym data"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"update \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` x
set x.synonyms = x.name
where domain_id in ('SURVEY')"

# add [rank1] for all items. this is to deal with the poly-hierarchical issue in many trees
echo "SYNONYMS - add [rank1]"
bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
"update \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\` x
set x.synonyms = CONCAT(x.synonyms, '|', y.rnk)
from
    (
        select min(id) as id, CONCAT('[', LOWER(domain_id), '_rank1]') as rnk
        from \`$BQ_PROJECT.$BQ_DATASET.cb_criteria\`
        where synonyms is not null
            and (est_count != -1 OR (est_count = -1 AND type = 'BRAND'))
        group by domain_id, is_standard, type, subtype, concept_id, name
    ) y
where x.id = y.id"


################################################
# DATABASE CLEAN UP - drop tables/views
################################################
#echo "DROP - prep_criteria"
#bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
#"DROP TABLE IF EXISTS \`$BQ_PROJECT.$BQ_DATASET.prep_criteria\`"
#
#echo "DROP - prep_criteria_ancestor"
#bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
#"DROP TABLE IF EXISTS \`$BQ_PROJECT.$BQ_DATASET.prep_criteria_ancestor\`"
#
#echo "DROP - prep_clinical_terms_nc"
#bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
#"DROP TABLE IF EXISTS \`$BQ_PROJECT.$BQ_DATASET.prep_clinical_terms_nc\`"
#
#echo "DROP - atc_rel_in_data"
#bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
#"DROP TABLE IF EXISTS \`$BQ_PROJECT.$BQ_DATASET.atc_rel_in_data\`"
#
#echo "DROP - loinc_rel_in_data"
#bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
#"DROP TABLE IF EXISTS \`$BQ_PROJECT.$BQ_DATASET.loinc_rel_in_data\`"
#
#echo "DROP - snomed_rel_cm_in_data"
#bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
#"DROP TABLE IF EXISTS \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_cm_in_data\`"
#
#echo "DROP - snomed_rel_cm_src_in_data"
#bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
#"DROP TABLE IF EXISTS \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_cm_src_in_data\`"
#
#echo "DROP - snomed_rel_pcs_in_data"
#bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
#"DROP TABLE IF EXISTS \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_pcs_in_data\`"
#
#echo "DROP - snomed_rel_meas_in_data"
#bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
#"DROP VIEW IF EXISTS \`$BQ_PROJECT.$BQ_DATASET.snomed_rel_meas_in_data\`"
#
#echo "DROP - v_loinc_rel"
#bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
#"DROP VIEW IF EXISTS \`$BQ_PROJECT.$BQ_DATASET.v_loinc_rel\`"
#
#echo "DROP - v_snomed_rel_cm"
#bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
#"DROP VIEW IF EXISTS \`$BQ_PROJECT.$BQ_DATASET.v_snomed_rel_cm\`"
#
#echo "DROP - v_snomed_rel_cm_src"
#bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
#"DROP VIEW IF EXISTS \`$BQ_PROJECT.$BQ_DATASET.v_snomed_rel_cm_src\`"
#
#echo "DROP - v_snomed_rel_pcs"
#bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
#"DROP VIEW IF EXISTS \`$BQ_PROJECT.$BQ_DATASET.v_snomed_rel_pcs\`"
#
#echo "DROP - v_snomed_rel_meas"
#bq --quiet --project=$BQ_PROJECT query --nouse_legacy_sql \
#"DROP VIEW IF EXISTS \`$BQ_PROJECT.$BQ_DATASET.v_snomed_rel_meas\`"
