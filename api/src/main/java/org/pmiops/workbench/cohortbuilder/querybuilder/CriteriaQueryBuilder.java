package org.pmiops.workbench.cohortbuilder.querybuilder;

import com.google.cloud.bigquery.QueryJobConfiguration;
import com.google.cloud.bigquery.QueryParameterValue;
import org.springframework.stereotype.Service;

/**
 * CriteriaQueryBuilder is an object that builds {@link QueryJobConfiguration}
 * for BigQuery for all of the cohort builder criteria trees.
 */
@Service
public class CriteriaQueryBuilder extends AbstractQueryBuilder {

    private static final String CRITERIA_QUERY =
            "select id,\n" +
                    "type,\n" +
                    "code,\n" +
                    "name,\n" +
                    "est_count,\n" +
                    "is_group,\n" +
                    "is_selectable,\n" +
                    "concept_id,\n" +
                    "domain_id\n" +
                    "from `${projectId}.${dataSetId}.${tableName}`\n" +
                    "where parent_id = @parentId\n" +
                    "order by id asc";

    @Override
    public QueryJobConfiguration buildQueryJobConfig(QueryParameters parameters) {
        return QueryJobConfiguration
                .newBuilder(CRITERIA_QUERY.replace("${tableName}", parameters.getType().toLowerCase() + "_criteria"))
                .addNamedParameter("parentId", QueryParameterValue.int64(parameters.getParentId()))
                .setUseLegacySql(false)
                .build();
    }

    @Override
    public FactoryKey getType() {
        return FactoryKey.CRITERIA;
    }
}
