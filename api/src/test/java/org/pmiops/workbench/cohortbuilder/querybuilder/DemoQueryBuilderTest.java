package org.pmiops.workbench.cohortbuilder.querybuilder;

import com.google.cloud.bigquery.QueryJobConfiguration;
import com.google.cloud.bigquery.QueryParameterValue;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.pmiops.workbench.model.Attribute;
import org.pmiops.workbench.model.SearchParameter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.junit4.SpringRunner;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import static org.junit.Assert.assertEquals;

@RunWith(SpringRunner.class)
@Import({DemoQueryBuilder.class})
public class DemoQueryBuilderTest {

    @Autowired
    DemoQueryBuilder queryBuilder;

    @Test
    public void buildQueryJobConfig() throws Exception {
        String genderNamedParameter = "";
        String ageNamedParameter = "";
        List<SearchParameter> params = new ArrayList<>();
        params.add(new SearchParameter().domain("DEMO").subtype("GEN").conceptId(8507L));
        params.add(new SearchParameter().domain("DEMO").subtype("AGE").attribute(new Attribute().operator("=").operands(Arrays.asList("18"))));

        QueryJobConfiguration queryJobConfiguration = queryBuilder
                .buildQueryJobConfig(new QueryParameters().type("DEMO").parameters(params));

        for (String key : queryJobConfiguration.getNamedParameters().keySet()) {
            if (key.startsWith("gen")) {
                genderNamedParameter = key;
            } else {
                ageNamedParameter = key;
            }
        }

        String expected = "select distinct person_id\n" +
                "from `${projectId}.${dataSetId}.person` p\n" +
                "where p.gender_concept_id = @" + genderNamedParameter + "\n" +
                "union distinct\n" +
                "select distinct person_id\n" +
                "from `${projectId}.${dataSetId}.person` p\n" +
                "where DATE_DIFF(CURRENT_DATE, DATE(p.year_of_birth, p.month_of_birth, p.day_of_birth), YEAR) =\n" +
                "@" + ageNamedParameter + "\n";

        assertEquals(expected, queryJobConfiguration.getQuery());

        assertEquals("8507", queryJobConfiguration
                .getNamedParameters()
                .get(genderNamedParameter)
                .getValue());
        assertEquals("18", queryJobConfiguration
                .getNamedParameters()
                .get(ageNamedParameter)
                .getValue());
    }

    @Test
    public void buildQueryJobConfig_NoAttributes() throws Exception {
        List<SearchParameter> params = new ArrayList<>();
        params.add(new SearchParameter().domain("DEMO").subtype("AGE"));

        try {
            queryBuilder
                    .buildQueryJobConfig(new QueryParameters().type("DEMO").parameters(params));
        } catch (IllegalArgumentException ex) {
            assertEquals("Age must provide an operator and operands.", ex.getMessage());
        }
    }

    @Test
    public void buildQueryJobConfig_AttributeWithNoOperands() throws Exception {
        List<SearchParameter> params = new ArrayList<>();
        params.add(new SearchParameter().domain("DEMO").subtype("AGE").attribute(new Attribute().operator("=")));

        try {
            queryBuilder
                    .buildQueryJobConfig(new QueryParameters().type("DEMO").parameters(params));
        } catch (IllegalArgumentException ex) {
            assertEquals("Age must provide an operator and operands.", ex.getMessage());
        }
    }

    @Test
    public void getType() throws Exception {
        assertEquals(FactoryKey.DEMO, queryBuilder.getType());
    }

}
