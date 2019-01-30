package org.pmiops.workbench.cohortbuilder.querybuilder;

import com.google.cloud.bigquery.QueryParameterValue;
import org.pmiops.workbench.model.SearchGroupItem;
import org.pmiops.workbench.model.SearchParameter;
import org.springframework.stereotype.Service;

import java.util.Map;

@Service
public class PhecodesQueryBuilder extends AbstractQueryBuilder {

    private static final String INNER_SQL_TEMPLATE =
            "select concept_id\n" +
                    "from `${projectId}.${dataSetId}.concept`\n" +
                    "where concept_code in\n" +
                    "(select icd9 from `${projectId}.${dataSetId}.phecode_criteria_icd`\n" +
                    "where phecode in unnest(${pheCodes}))\n" +
                    "and vocabulary_id in ('ICD9Proc', 'ICD9CM')\n";

    private static final String OUTER_SQL_TEMPLATE =
            "select person_id\n" +
                    "from `${projectId}.${dataSetId}.condition_occurrence` co\n" +
                    "where co.condition_source_concept_id in (${innerSql})\n" +
                    "union all\n" +
            "select person_id\n" +
                    "from `${projectId}.${dataSetId}.procedure_occurrence` po\n" +
                    "where po.procedure_source_concept_id in (${innerSql})\n" +
                    "union all\n" +
            "select person_id\n" +
                    "from `${projectId}.${dataSetId}.measurement` m\n" +
                    "where m.measurement_source_concept_id in (${innerSql})\n" +
                    "union all\n" +
            "select person_id\n" +
                    "from `${projectId}.${dataSetId}.observation` o\n" +
                    "where o.observation_source_concept_id in (${innerSql})\n";

    @Override
    public String buildQuery(Map<String, QueryParameterValue> queryParams,
                             SearchGroupItem searchGroupItem,
                             String temporalMention) {
        String namedParameter = addQueryParameterValue(queryParams,
                QueryParameterValue.array(
                        searchGroupItem
                                .getSearchParameters()
                                .stream()
                                .map(SearchParameter::getValue)
                                .toArray(String[]::new), String.class));
        String innerSql = INNER_SQL_TEMPLATE.replace("${pheCodes}", "@" + namedParameter);
        return OUTER_SQL_TEMPLATE.replace("${innerSql}", innerSql);
    }

    @Override
    public FactoryKey getType() {
        return FactoryKey.PHECODE;
    }
}
