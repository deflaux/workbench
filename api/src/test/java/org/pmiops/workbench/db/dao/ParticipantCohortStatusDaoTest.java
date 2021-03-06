package org.pmiops.workbench.db.dao;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.fail;

import java.sql.Date;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import org.junit.After;
import org.junit.Before;
import org.junit.FixMethodOrder;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.junit.runners.MethodSorters;
import org.pmiops.workbench.cdr.CdrVersionContext;
import org.pmiops.workbench.db.model.CdrVersion;
import org.pmiops.workbench.db.model.ParticipantCohortStatus;
import org.pmiops.workbench.db.model.ParticipantCohortStatusKey;
import org.pmiops.workbench.exceptions.BadRequestException;
import org.pmiops.workbench.model.CohortStatus;
import org.pmiops.workbench.model.Filter;
import org.pmiops.workbench.model.Operator;
import org.pmiops.workbench.model.PageRequest;
import org.pmiops.workbench.model.ParticipantCohortStatusColumns;
import org.pmiops.workbench.model.SortOrder;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.liquibase.LiquibaseAutoConfiguration;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.context.annotation.Import;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.context.junit4.SpringRunner;
import org.springframework.transaction.annotation.Transactional;

@RunWith(SpringRunner.class)
@DataJpaTest
@Import({LiquibaseAutoConfiguration.class})
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@Transactional
@FixMethodOrder(MethodSorters.NAME_ASCENDING)
public class ParticipantCohortStatusDaoTest {
  private static Long COHORT_REVIEW_ID = 1L;

  @Autowired private ParticipantCohortStatusDao participantCohortStatusDao;

  @Autowired private JdbcTemplate jdbcTemplate;

  private int page;
  private int pageSize;

  @Before
  public void onSetup() {
    page = 0;
    pageSize = 25;

    CdrVersion cdrVersion = new CdrVersion();
    cdrVersion.setCdrDbName("");
    CdrVersionContext.setCdrVersionNoCheckAuthDomain(cdrVersion);

    jdbcTemplate.execute(
        "insert into participant_cohort_status"
            + "(cohort_review_id, participant_id, status, gender_concept_id, birth_date, race_concept_id, ethnicity_concept_id, deceased)"
            + "values (1, 1, 1, 8507, sysdate(), 8515, 38003564, 0)");
    jdbcTemplate.execute(
        "insert into participant_cohort_status"
            + "(cohort_review_id, participant_id, status, gender_concept_id, birth_date, race_concept_id, ethnicity_concept_id, deceased)"
            + "values (1, 2, 0, 8507, sysdate(), 8515, 38003564, 0)");
    jdbcTemplate.execute(
        "insert into concept"
            + "(concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, count_value, prevalence)"
            + "values (8507, 'MALE', 3, 'Gender', 1, 'c', 'c', 1, 1)");
    jdbcTemplate.execute(
        "insert into concept"
            + "(concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, count_value, prevalence)"
            + "values (8515, 'Asian', 3, 'Race', 1, 'c', 'c', 1, 1)");
    jdbcTemplate.execute(
        "insert into concept"
            + "(concept_id, concept_name, domain_id, vocabulary_id, concept_class_id, standard_concept, concept_code, count_value, prevalence)"
            + "values (38003564, 'Not Hispanic or Latino', 3, 'Ethnicity', 1, 'c', 'c', 1, 1)");
  }

  @After
  public void onTearDown() {
    jdbcTemplate.execute("delete from participant_cohort_status");
    jdbcTemplate.execute("delete from concept");
  }

  @Test
  public void findByParticipantKeyCohortReviewIdAndParticipantKeyParticipantId() throws Exception {
    ParticipantCohortStatus participant1 =
        createExpectedPCS(
            new ParticipantCohortStatusKey().cohortReviewId(COHORT_REVIEW_ID).participantId(1),
            CohortStatus.INCLUDED);
    ParticipantCohortStatus actualParticipant =
        participantCohortStatusDao
            .findByParticipantKey_CohortReviewIdAndParticipantKey_ParticipantId(
                COHORT_REVIEW_ID, participant1.getParticipantKey().getParticipantId());
    participant1.setBirthDate(actualParticipant.getBirthDate());
    assertEquals(participant1, actualParticipant);
  }

  /**
   * Prefixed this test with a a zzz to ensure that it runs last using the {@link FixMethodOrder}
   * annotation. This method has to run last because the batching implementation has to call a
   * commit. This commit causes problems with other test cases results.
   *
   * @throws Exception
   */
  @Test
  public void findAllSaveParticipantCohortStatuses() throws Exception {
    ParticipantCohortStatusKey key1 =
        new ParticipantCohortStatusKey().cohortReviewId(2).participantId(3);
    ParticipantCohortStatusKey key2 =
        new ParticipantCohortStatusKey().cohortReviewId(2).participantId(4);
    ParticipantCohortStatus pcs1 =
        new ParticipantCohortStatus()
            .participantKey(key1)
            .statusEnum(CohortStatus.INCLUDED)
            .birthDate(new Date(System.currentTimeMillis()))
            .ethnicityConceptId(1L)
            .genderConceptId(1L)
            .raceConceptId(1L)
            .deceased(false);
    ParticipantCohortStatus pcs2 =
        new ParticipantCohortStatus()
            .participantKey(key2)
            .statusEnum(CohortStatus.EXCLUDED)
            .birthDate(new Date(System.currentTimeMillis()))
            .ethnicityConceptId(1L)
            .genderConceptId(1L)
            .raceConceptId(1L)
            .deceased(false);

    participantCohortStatusDao.saveParticipantCohortStatusesCustom(Arrays.asList(pcs1, pcs2));

    String sql = "select count(*) from participant_cohort_status where cohort_review_id = ?";
    final Object[] sqlParams = {key1.getCohortReviewId()};
    final Integer expectedCount = new Integer("2");

    assertEquals(expectedCount, jdbcTemplate.queryForObject(sql, sqlParams, Integer.class));
  }

  @Test
  public void findAllNoMatchingConcept() throws Exception {
    jdbcTemplate.execute("delete from concept");

    PageRequest pageRequest =
        new PageRequest()
            .page(page)
            .pageSize(pageSize)
            .sortOrder(SortOrder.ASC)
            .sortColumn(ParticipantCohortStatusColumns.PARTICIPANTID.toString());
    List<ParticipantCohortStatus> results =
        participantCohortStatusDao.findAll(1L, Collections.<Filter>emptyList(), pageRequest);

    assertEquals(2, results.size());
  }

  @Test
  public void findAllNoSearchCriteria() throws Exception {
    PageRequest pageRequest =
        new PageRequest()
            .page(page)
            .pageSize(pageSize)
            .sortOrder(SortOrder.ASC)
            .sortColumn(ParticipantCohortStatusColumns.PARTICIPANTID.toString());
    List<ParticipantCohortStatus> results =
        participantCohortStatusDao.findAll(1L, Collections.<Filter>emptyList(), pageRequest);

    assertEquals(2, results.size());

    ParticipantCohortStatus participant1 =
        createExpectedPCS(
            new ParticipantCohortStatusKey().cohortReviewId(COHORT_REVIEW_ID).participantId(1),
            CohortStatus.INCLUDED);
    participant1.setBirthDate(results.get(0).getBirthDate());
    ParticipantCohortStatus participant2 =
        createExpectedPCS(
            new ParticipantCohortStatusKey().cohortReviewId(COHORT_REVIEW_ID).participantId(1),
            CohortStatus.EXCLUDED);
    participant2.setBirthDate(results.get(1).getBirthDate());

    assertEquals(participant1, results.get(0));
    assertEquals(participant2, results.get(1));
  }

  @Test
  public void findAllSearchCriteriaEqual() throws Exception {
    PageRequest pageRequest =
        new PageRequest()
            .page(page)
            .pageSize(pageSize)
            .sortOrder(SortOrder.ASC)
            .sortColumn(ParticipantCohortStatusColumns.PARTICIPANTID.toString());
    List<Filter> filters = new ArrayList<>();
    filters.add(
        new Filter()
            .property(ParticipantCohortStatusColumns.PARTICIPANTID)
            .operator(Operator.EQUAL)
            .values(Arrays.asList("1")));
    filters.add(
        new Filter()
            .property(ParticipantCohortStatusColumns.STATUS)
            .operator(Operator.EQUAL)
            .values(Arrays.asList(CohortStatus.INCLUDED.toString())));
    filters.add(
        new Filter()
            .property(ParticipantCohortStatusColumns.BIRTHDATE)
            .operator(Operator.EQUAL)
            .values(Arrays.asList(new Date(System.currentTimeMillis()).toString())));
    filters.add(
        new Filter()
            .property(ParticipantCohortStatusColumns.GENDER)
            .operator(Operator.EQUAL)
            .values(Arrays.asList("8507")));
    filters.add(
        new Filter()
            .property(ParticipantCohortStatusColumns.RACE)
            .operator(Operator.EQUAL)
            .values(Arrays.asList("8515")));
    filters.add(
        new Filter()
            .property(ParticipantCohortStatusColumns.ETHNICITY)
            .operator(Operator.EQUAL)
            .values(Arrays.asList("38003564")));
    List<ParticipantCohortStatus> results =
        participantCohortStatusDao.findAll(1L, filters, pageRequest);

    assertEquals(1, results.size());

    ParticipantCohortStatus expectedPCS =
        createExpectedPCS(
            new ParticipantCohortStatusKey().cohortReviewId(COHORT_REVIEW_ID).participantId(1),
            CohortStatus.INCLUDED);
    expectedPCS.setBirthDate(results.get(0).getBirthDate());

    assertEquals(expectedPCS, results.get(0));
  }

  @Test
  public void findAllSearchCriteriaIn() throws Exception {
    PageRequest pageRequest =
        new PageRequest()
            .page(page)
            .pageSize(pageSize)
            .sortOrder(SortOrder.ASC)
            .sortColumn(ParticipantCohortStatusColumns.PARTICIPANTID.toString());
    List<Filter> filters = new ArrayList<>();
    filters.add(
        new Filter()
            .property(ParticipantCohortStatusColumns.PARTICIPANTID)
            .operator(Operator.IN)
            .values(Arrays.asList("1", "2")));
    filters.add(
        new Filter()
            .property(ParticipantCohortStatusColumns.STATUS)
            .operator(Operator.IN)
            .values(
                Arrays.asList(CohortStatus.INCLUDED.toString(), CohortStatus.EXCLUDED.toString())));
    filters.add(
        new Filter()
            .property(ParticipantCohortStatusColumns.BIRTHDATE)
            .operator(Operator.IN)
            .values(Arrays.asList(new Date(System.currentTimeMillis()).toString())));
    filters.add(
        new Filter()
            .property(ParticipantCohortStatusColumns.GENDER)
            .operator(Operator.IN)
            .values(Arrays.asList("8507", "8532")));
    filters.add(
        new Filter()
            .property(ParticipantCohortStatusColumns.RACE)
            .operator(Operator.IN)
            .values(Arrays.asList("8515", "8527")));
    filters.add(
        new Filter()
            .property(ParticipantCohortStatusColumns.ETHNICITY)
            .operator(Operator.IN)
            .values(Arrays.asList("38003564", "38003563")));
    List<ParticipantCohortStatus> results =
        participantCohortStatusDao.findAll(1L, filters, pageRequest);

    assertEquals(2, results.size());

    ParticipantCohortStatus expectedPCS1 =
        createExpectedPCS(
            new ParticipantCohortStatusKey().cohortReviewId(COHORT_REVIEW_ID).participantId(1),
            CohortStatus.INCLUDED);
    expectedPCS1.setBirthDate(results.get(0).getBirthDate());
    ParticipantCohortStatus expectedPCS2 =
        createExpectedPCS(
            new ParticipantCohortStatusKey().cohortReviewId(COHORT_REVIEW_ID).participantId(2),
            CohortStatus.EXCLUDED);
    expectedPCS2.setBirthDate(results.get(0).getBirthDate());

    assertEquals(expectedPCS1, results.get(0));
    assertEquals(expectedPCS2, results.get(1));
  }

  @Test
  public void findAllPaging() throws Exception {
    PageRequest pageRequest =
        new PageRequest()
            .page(page)
            .pageSize(1)
            .sortOrder(SortOrder.ASC)
            .sortColumn(ParticipantCohortStatusColumns.PARTICIPANTID.toString());
    List<ParticipantCohortStatus> results =
        participantCohortStatusDao.findAll(1L, Collections.<Filter>emptyList(), pageRequest);

    assertEquals(1, results.size());

    ParticipantCohortStatus expectedPCS =
        createExpectedPCS(
            new ParticipantCohortStatusKey().cohortReviewId(COHORT_REVIEW_ID).participantId(1),
            CohortStatus.INCLUDED);
    expectedPCS.setBirthDate(results.get(0).getBirthDate());

    assertEquals(expectedPCS, results.get(0));

    pageRequest =
        new PageRequest()
            .page(1)
            .pageSize(1)
            .sortOrder(SortOrder.ASC)
            .sortColumn(ParticipantCohortStatusColumns.PARTICIPANTID.toString());
    results = participantCohortStatusDao.findAll(1L, Collections.<Filter>emptyList(), pageRequest);

    assertEquals(1, results.size());

    expectedPCS =
        createExpectedPCS(
            new ParticipantCohortStatusKey().cohortReviewId(COHORT_REVIEW_ID).participantId(2),
            CohortStatus.EXCLUDED);
    expectedPCS.setBirthDate(results.get(0).getBirthDate());

    assertEquals(expectedPCS, results.get(0));
  }

  @Test
  public void findCount() throws Exception {
    PageRequest pageRequest =
        new PageRequest()
            .page(page)
            .pageSize(1)
            .sortOrder(SortOrder.ASC)
            .sortColumn(ParticipantCohortStatusColumns.PARTICIPANTID.toString());
    Long results =
        participantCohortStatusDao.findCount(1L, Collections.<Filter>emptyList(), pageRequest);

    assertEquals(2L, results.longValue());
  }

  @Test
  public void findAllParticipantIdSorting() throws Exception {
    PageRequest pageRequest =
        new PageRequest()
            .page(page)
            .pageSize(2)
            .sortOrder(SortOrder.ASC)
            .sortColumn(ParticipantCohortStatusColumns.PARTICIPANTID.toString());
    List<ParticipantCohortStatus> results =
        participantCohortStatusDao.findAll(1L, Collections.<Filter>emptyList(), pageRequest);

    assertEquals(2, results.size());

    ParticipantCohortStatus expectedPCS1 =
        createExpectedPCS(
            new ParticipantCohortStatusKey().cohortReviewId(COHORT_REVIEW_ID).participantId(1),
            CohortStatus.INCLUDED);
    expectedPCS1.setBirthDate(results.get(0).getBirthDate());
    ParticipantCohortStatus expectedPCS2 =
        createExpectedPCS(
            new ParticipantCohortStatusKey().cohortReviewId(COHORT_REVIEW_ID).participantId(2),
            CohortStatus.EXCLUDED);
    expectedPCS2.setBirthDate(results.get(1).getBirthDate());

    assertEquals(expectedPCS1, results.get(0));
    assertEquals(expectedPCS2, results.get(1));

    pageRequest =
        new PageRequest()
            .page(page)
            .pageSize(2)
            .sortOrder(SortOrder.DESC)
            .sortColumn(ParticipantCohortStatusColumns.PARTICIPANTID.toString());
    results = participantCohortStatusDao.findAll(1L, Collections.<Filter>emptyList(), pageRequest);

    assertEquals(2, results.size());

    expectedPCS1 =
        createExpectedPCS(
            new ParticipantCohortStatusKey().cohortReviewId(COHORT_REVIEW_ID).participantId(2),
            CohortStatus.EXCLUDED);
    expectedPCS1.setBirthDate(results.get(0).getBirthDate());
    expectedPCS2 =
        createExpectedPCS(
            new ParticipantCohortStatusKey().cohortReviewId(COHORT_REVIEW_ID).participantId(1),
            CohortStatus.INCLUDED);
    expectedPCS2.setBirthDate(results.get(1).getBirthDate());

    assertEquals(expectedPCS1, results.get(0));
    assertEquals(expectedPCS2, results.get(1));
  }

  @Test
  public void findAllStatusSorting() throws Exception {
    PageRequest pageRequest =
        new PageRequest()
            .page(page)
            .pageSize(2)
            .sortOrder(SortOrder.ASC)
            .sortColumn(ParticipantCohortStatusColumns.STATUS.toString());
    List<ParticipantCohortStatus> results =
        participantCohortStatusDao.findAll(1L, Collections.<Filter>emptyList(), pageRequest);

    assertEquals(2, results.size());

    ParticipantCohortStatus expectedPCS1 =
        createExpectedPCS(
            new ParticipantCohortStatusKey().cohortReviewId(COHORT_REVIEW_ID).participantId(2),
            CohortStatus.EXCLUDED);
    expectedPCS1.setBirthDate(results.get(0).getBirthDate());
    ParticipantCohortStatus expectedPCS2 =
        createExpectedPCS(
            new ParticipantCohortStatusKey().cohortReviewId(COHORT_REVIEW_ID).participantId(1),
            CohortStatus.INCLUDED);
    expectedPCS2.setBirthDate(results.get(1).getBirthDate());

    assertEquals(expectedPCS1, results.get(0));
    assertEquals(expectedPCS2, results.get(1));

    pageRequest =
        new PageRequest()
            .page(page)
            .pageSize(2)
            .sortOrder(SortOrder.DESC)
            .sortColumn(ParticipantCohortStatusColumns.STATUS.toString());
    results = participantCohortStatusDao.findAll(1L, Collections.<Filter>emptyList(), pageRequest);

    assertEquals(2, results.size());

    expectedPCS1 =
        createExpectedPCS(
            new ParticipantCohortStatusKey().cohortReviewId(COHORT_REVIEW_ID).participantId(1),
            CohortStatus.INCLUDED);
    expectedPCS1.setBirthDate(results.get(0).getBirthDate());
    expectedPCS2 =
        createExpectedPCS(
            new ParticipantCohortStatusKey().cohortReviewId(COHORT_REVIEW_ID).participantId(2),
            CohortStatus.EXCLUDED);
    expectedPCS2.setBirthDate(results.get(1).getBirthDate());

    assertEquals(expectedPCS1, results.get(0));
    assertEquals(expectedPCS2, results.get(1));
  }

  @Test
  public void findAllBadFilterTypes() throws Exception {
    PageRequest pageRequest =
        new PageRequest()
            .page(page)
            .pageSize(pageSize)
            .sortOrder(SortOrder.ASC)
            .sortColumn(ParticipantCohortStatusColumns.PARTICIPANTID.toString());
    List<Filter> filters = new ArrayList<>();

    filters.add(
        new Filter()
            .property(ParticipantCohortStatusColumns.PARTICIPANTID)
            .operator(Operator.EQUAL)
            .values(Arrays.asList("z")));
    assertBadRequest(
        pageRequest,
        filters,
        "Bad Request: Problems parsing PARTICIPANTID: For input string: \"z\"");

    filters.clear();
    filters.add(
        new Filter()
            .property(ParticipantCohortStatusColumns.STATUS)
            .operator(Operator.EQUAL)
            .values(Arrays.asList("z")));
    assertBadRequest(
        pageRequest,
        filters,
        "Bad Request: Problems parsing STATUS: No enum constant org.pmiops.workbench.model.CohortStatus.z");

    filters.clear();
    filters.add(
        new Filter()
            .property(ParticipantCohortStatusColumns.BIRTHDATE)
            .operator(Operator.EQUAL)
            .values(Arrays.asList("z")));
    assertBadRequest(
        pageRequest, filters, "Bad Request: Problems parsing BIRTHDATE: Unparseable date: \"z\"");
  }

  @Test
  public void findAllBadFilterValuesSize() throws Exception {
    PageRequest pageRequest =
        new PageRequest()
            .page(page)
            .pageSize(pageSize)
            .sortOrder(SortOrder.ASC)
            .sortColumn(ParticipantCohortStatusColumns.PARTICIPANTID.toString());
    List<Filter> filters = new ArrayList<>();

    filters.add(
        new Filter()
            .property(ParticipantCohortStatusColumns.PARTICIPANTID)
            .operator(Operator.EQUAL)
            .values(Arrays.asList("1", "2")));
    assertBadRequest(
        pageRequest,
        filters,
        "Bad Request: property PARTICIPANTID using operator EQUAL must have a single value.");

    filters.clear();
    filters.add(
        new Filter()
            .property(ParticipantCohortStatusColumns.STATUS)
            .operator(Operator.EQUAL)
            .values(new ArrayList<>()));
    assertBadRequest(pageRequest, filters, "Bad Request: property STATUS is empty.");
  }

  private void assertBadRequest(
      PageRequest pageRequest, List<Filter> filters, String expectedException) {
    try {
      participantCohortStatusDao.findAll(1L, filters, pageRequest);
      fail("Should have thrown BadRequestException!");
    } catch (BadRequestException e) {
      assertEquals(expectedException, e.getMessage());
    }
  }

  private ParticipantCohortStatus createExpectedPCS(
      ParticipantCohortStatusKey key, CohortStatus status) {
    return new ParticipantCohortStatus()
        .participantKey(key)
        .statusEnum(status)
        .ethnicityConceptId(38003564L)
        .genderConceptId(8507L)
        .raceConceptId(8515L);
  }
}
