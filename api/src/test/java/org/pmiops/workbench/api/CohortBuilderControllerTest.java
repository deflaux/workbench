package org.pmiops.workbench.api;


import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.pmiops.workbench.cdr.CdrVersionService;
import org.pmiops.workbench.cdr.dao.ConceptDao;
import org.pmiops.workbench.cdr.dao.ConceptRelationshipDao;
import org.pmiops.workbench.cdr.dao.CriteriaDao;
import org.pmiops.workbench.cdr.model.Concept;
import org.pmiops.workbench.cdr.model.ConceptRelationship;
import org.pmiops.workbench.cdr.model.ConceptRelationshipId;
import org.pmiops.workbench.cdr.model.Criteria;
import org.pmiops.workbench.cohortbuilder.ParticipantCounter;
import org.pmiops.workbench.db.dao.CdrVersionDao;
import org.pmiops.workbench.model.DomainType;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.liquibase.LiquibaseAutoConfiguration;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.junit4.SpringRunner;
import org.springframework.transaction.annotation.Transactional;

import static org.junit.Assert.assertEquals;

@RunWith(SpringRunner.class)
@DataJpaTest
@Import(LiquibaseAutoConfiguration.class)
@AutoConfigureTestDatabase(replace= AutoConfigureTestDatabase.Replace.NONE)
@Transactional
public class CohortBuilderControllerTest {

  private static final String TYPE_ICD9 = "ICD9";
  private static final String TYPE_DEMO = "DEMO";
  private static final String TYPE_MEASUREMENT = "MEAS";
  private static final String TYPE_DRUG = "DRUG";
  private static final String SUBTYPE_NONE = null;
  private static final String SUBTYPE_AGE = "AGE";
  private static final String SUBTYPE_LAB = "LAB";
  private static final String SUBTYPE_ATC = "ATC";
  private static final String SUBTYPE_BRAND = "BRAND";

  private Criteria icd9CriteriaParent;
  private Criteria icd9CriteriaChild;
  private Criteria demoCriteria;
  private Criteria labMeasurement;
  private Criteria drugATCCriteria;
  private Criteria drugBrandCriteria;

  @Autowired
  private CohortBuilderController controller;

  @Autowired
  private CriteriaDao criteriaDao;

  @Autowired
  private ConceptDao conceptDao;

  @Autowired
  private ConceptRelationshipDao conceptRelationshipDao;

  @TestConfiguration
  @Import({
    CohortBuilderController.class
  })
  @MockBean({
    CdrVersionService.class,
    CdrVersionDao.class,
    BigQueryService.class,
    ParticipantCounter.class
  })
  static class Configuration {}

  @Before
  public void setUp() {
    icd9CriteriaParent = criteriaDao.save(
      createCriteria(TYPE_ICD9, SUBTYPE_NONE, 0L, "001", "name", DomainType.CONDITION.name(), null, true)
    );
    icd9CriteriaChild = criteriaDao.save(
      createCriteria(TYPE_ICD9, SUBTYPE_NONE, icd9CriteriaParent.getId(), "001.1", "name", DomainType.CONDITION.name(), null, false)
    );
    demoCriteria = criteriaDao.save(
      createCriteria(TYPE_DEMO, SUBTYPE_AGE, 0L, null, "age", null, null, true)
    );
    labMeasurement = criteriaDao.save(
      createCriteria(TYPE_MEASUREMENT, SUBTYPE_LAB, 0L, "xxxLP12345", "name", DomainType.MEASUREMENT.name(), null, true)
    );
    drugATCCriteria = criteriaDao.save(
      createCriteria(TYPE_DRUG, SUBTYPE_ATC, 0L, "LP12345", "drugName", DomainType.DRUG.name(), "12345", true)
    );
    drugBrandCriteria = criteriaDao.save(
      createCriteria(TYPE_DRUG, SUBTYPE_BRAND, 0L, "LP12345", "brandName", DomainType.DRUG.name(), "1235", true)
    );
    conceptDao.save(new Concept().conceptId(12345).conceptClassId("Ingredient"));
    conceptRelationshipDao.save(
      new ConceptRelationship().conceptRelationshipId(
        new ConceptRelationshipId()
          .relationshipId("1")
          .conceptId2(12345)
          .conceptId1(1247)
      )
    );
  }

  @Test
  public void getCriteriaByTypeAndParentId() throws Exception {
    assertEquals(
      createResponseCriteria(icd9CriteriaParent),
      controller
        .getCriteriaByTypeAndParentId(1L, TYPE_ICD9, 0L)
        .getBody()
        .getItems()
        .get(0)
    );
    assertEquals(
      createResponseCriteria(icd9CriteriaChild),
      controller
        .getCriteriaByTypeAndParentId(1L, TYPE_ICD9, icd9CriteriaParent.getId())
        .getBody()
        .getItems()
        .get(0)
    );
  }

  @Test
  public void getCriteriaByTypeAndSubtype() throws Exception {
    assertEquals(
      createResponseCriteria(demoCriteria),
      controller
        .getCriteriaByTypeAndSubtype(1L, TYPE_DEMO, SUBTYPE_AGE)
        .getBody()
        .getItems()
        .get(0)
    );
  }

  @Test
  public void getCriteriaByTypeForCodeOrName() throws Exception {
    assertEquals(
      createResponseCriteria(labMeasurement),
      controller
        .getCriteriaByTypeForCodeOrName(1L, "MEAS", "LP12")
        .getBody()
        .getItems()
        .get(0)
    );
  }

  @Test
  public void getDrugBrandOrIngredientByName() throws Exception {
    assertEquals(
      createResponseCriteria(drugATCCriteria),
      controller
        .getDrugBrandOrIngredientByName(1L, "drugN")
        .getBody()
        .getItems()
        .get(0)
    );

    assertEquals(
      createResponseCriteria(drugBrandCriteria),
      controller
        .getDrugBrandOrIngredientByName(1L, "brandN")
        .getBody()
        .getItems()
        .get(0)
    );
  }

  @Test
  public void getDrugIngredientByConceptId() throws Exception {
    assertEquals(
      createResponseCriteria(drugATCCriteria),
      controller
        .getDrugIngredientByConceptId(1L, 1247L)
        .getBody()
        .getItems()
        .get(0)
    );
  }

  @Test
  public void getCriteriaByType() throws Exception {
    assertEquals(
      createResponseCriteria(drugATCCriteria),
      controller
        .getCriteriaByType(1L, drugATCCriteria.getType())
        .getBody()
        .getItems()
        .get(0)
    );
  }

  private Criteria createCriteria(String type, String subtype, long parentId, String code, String name, String domain, String conceptId, boolean group) {
    return new Criteria()
      .parentId(parentId)
      .type(type)
      .subtype(subtype)
      .code(code)
      .name(name)
      .group(group)
      .selectable(true)
      .count("16")
      .domainId(domain)
      .conceptId(conceptId);
  }

  private org.pmiops.workbench.model.Criteria createResponseCriteria(Criteria criteria) {
    return new org.pmiops.workbench.model.Criteria()
      .code(criteria.getCode())
      .conceptId(criteria.getConceptId() == null ? null : new Long(criteria.getConceptId()))
      .count(new Long(criteria.getCount()))
      .domainId(criteria.getDomainId())
      .group(criteria.getGroup())
      .hasAttributes(criteria.getAttribute())
      .id(criteria.getId())
      .name(criteria.getName())
      .parentId(criteria.getParentId())
      .selectable(criteria.getSelectable())
      .subtype(criteria.getSubtype())
      .type(criteria.getType())
      .predefinedAttributes(null);
  }
}