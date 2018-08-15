package org.pmiops.workbench.api;

import com.google.cloud.bigquery.FieldValue;
import com.google.cloud.bigquery.QueryJobConfiguration;
import com.google.cloud.bigquery.QueryResult;
import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import org.pmiops.workbench.cdr.CdrVersionService;
import org.pmiops.workbench.cdr.cache.GenderRaceEthnicityConcept;
import org.pmiops.workbench.cdr.dao.CriteriaDao;
import org.pmiops.workbench.cdr.model.Criteria;
import org.pmiops.workbench.cohortbuilder.ParticipantCounter;
import org.pmiops.workbench.cohortbuilder.ParticipantCriteria;
import org.pmiops.workbench.db.dao.CdrVersionDao;
import org.pmiops.workbench.model.Attribute;
import org.pmiops.workbench.model.ChartInfo;
import org.pmiops.workbench.model.ChartInfoListResponse;
import org.pmiops.workbench.model.ConceptIdName;
import org.pmiops.workbench.model.CriteriaAttributeListResponse;
import org.pmiops.workbench.model.CriteriaListResponse;
import org.pmiops.workbench.model.ParticipantCohortStatusColumns;
import org.pmiops.workbench.model.ParticipantDemographics;
import org.pmiops.workbench.model.SearchRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.RestController;

import javax.inject.Provider;
import java.lang.reflect.Type;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.function.Function;
import java.util.stream.Collectors;

@RestController
public class CohortBuilderController implements CohortBuilderApiDelegate {

  private BigQueryService bigQueryService;
  private ParticipantCounter participantCounter;
  private CriteriaDao criteriaDao;
  private CdrVersionDao cdrVersionDao;
  private Provider<GenderRaceEthnicityConcept> genderRaceEthnicityConceptProvider;
  private CdrVersionService cdrVersionService;

  /**
   * Converter function from backend representation (used with Hibernate) to
   * client representation (generated by Swagger).
   */
  private static final Function<Criteria, org.pmiops.workbench.model.Criteria>
    TO_CLIENT_CRITERIA =
    new Function<Criteria, org.pmiops.workbench.model.Criteria>() {
      @Override
      public org.pmiops.workbench.model.Criteria apply(Criteria criteria) {
        Type listType = new TypeToken<ArrayList<Attribute>>() {
        }.getType();
        List<Attribute> predefinedAttributes = new Gson().fromJson(criteria.getPredefinedAttributes(), listType);
        return new org.pmiops.workbench.model.Criteria()
          .id(criteria.getId())
          .parentId(criteria.getParentId())
          .type(criteria.getType())
          .subtype(criteria.getSubtype())
          .code(criteria.getCode())
          .name(criteria.getName())
          .count(StringUtils.isEmpty(criteria.getCount()) ? null : new Long(criteria.getCount()))
          .group(criteria.getGroup())
          .selectable(criteria.getSelectable())
          .conceptId(StringUtils.isEmpty(criteria.getConceptId()) ? null : new Long(criteria.getConceptId()))
          .domainId(criteria.getDomainId())
          .hasAttributes(criteria.getAttribute())
          .predefinedAttributes(predefinedAttributes);
      }
    };

  @Autowired
  CohortBuilderController(BigQueryService bigQueryService,
                          ParticipantCounter participantCounter,
                          CriteriaDao criteriaDao,
                          CdrVersionDao cdrVersionDao,
                          Provider<GenderRaceEthnicityConcept> genderRaceEthnicityConceptProvider,
                          CdrVersionService cdrVersionService) {
    this.bigQueryService = bigQueryService;
    this.participantCounter = participantCounter;
    this.criteriaDao = criteriaDao;
    this.cdrVersionDao = cdrVersionDao;
    this.genderRaceEthnicityConceptProvider = genderRaceEthnicityConceptProvider;
    this.cdrVersionService = cdrVersionService;
  }

  /**
   * This method list any of the criteria trees.
   */
  @Override
  public ResponseEntity<CriteriaListResponse> getCriteriaByTypeAndParentId(Long cdrVersionId, String type, Long parentId) {
    cdrVersionService.setCdrVersion(cdrVersionDao.findOne(cdrVersionId));
    final List<Criteria> criteriaList = criteriaDao.findCriteriaByTypeAndParentIdOrderByIdAsc(type, parentId);

    CriteriaListResponse criteriaResponse = new CriteriaListResponse();
    criteriaResponse.setItems(criteriaList.stream().map(TO_CLIENT_CRITERIA).collect(Collectors.toList()));

    return ResponseEntity.ok(criteriaResponse);
  }

  @Override
  public ResponseEntity<CriteriaListResponse> getCriteriaByTypeAndSubtype(Long cdrVersionId, String type, String subtype) {
    cdrVersionService.setCdrVersion(cdrVersionDao.findOne(cdrVersionId));
    final List<Criteria> criteriaList = criteriaDao.findCriteriaByTypeAndSubtypeOrderByIdAsc(type, subtype);

    CriteriaListResponse criteriaResponse = new CriteriaListResponse();
    criteriaResponse.setItems(criteriaList.stream().map(TO_CLIENT_CRITERIA).collect(Collectors.toList()));

    return ResponseEntity.ok(criteriaResponse);
  }

  @Override
  public ResponseEntity<CriteriaListResponse> getCriteriaByTypeForCodeOrName(Long cdrVersionId,
                                                                             String type,
                                                                             String value) {
    cdrVersionService.setCdrVersion(cdrVersionDao.findOne(cdrVersionId));
    final List<Criteria> criteriaList = criteriaDao.findCriteriaByTypeForCodeOrName(type, value);

    CriteriaListResponse criteriaResponse = new CriteriaListResponse();
    criteriaResponse.setItems(criteriaList.stream().map(TO_CLIENT_CRITERIA).collect(Collectors.toList()));

    return ResponseEntity.ok(criteriaResponse);
  }

  @Override
  public ResponseEntity<CriteriaListResponse> getDrugBrandOrIngredientByName(Long cdrVersionId, String drugName) {
    cdrVersionService.setCdrVersion(cdrVersionDao.findOne(cdrVersionId));
    final List<Criteria> criteriaList = criteriaDao.findDrugBrandOrIngredientByName(drugName);

    CriteriaListResponse criteriaResponse = new CriteriaListResponse();
    criteriaResponse.setItems(criteriaList.stream().map(TO_CLIENT_CRITERIA).collect(Collectors.toList()));

    return ResponseEntity.ok(criteriaResponse);
  }

  @Override
  public ResponseEntity<CriteriaListResponse> getDrugIngredientByConceptId(Long cdrVersionId, Long conceptId) {
    cdrVersionService.setCdrVersion(cdrVersionDao.findOne(cdrVersionId));
    final List<Criteria> criteriaList = criteriaDao.findDrugIngredientByConceptId(conceptId);

    CriteriaListResponse criteriaResponse = new CriteriaListResponse();
    criteriaResponse.setItems(criteriaList.stream().map(TO_CLIENT_CRITERIA).collect(Collectors.toList()));

    return ResponseEntity.ok(criteriaResponse);
  }

  /**
   * This method will return a count of unique subjects
   * defined by the provided {@link SearchRequest}.
   */
  @Override
  public ResponseEntity<Long> countParticipants(Long cdrVersionId, SearchRequest request) {
    cdrVersionService.setCdrVersion(cdrVersionDao.findOne(cdrVersionId));

    QueryJobConfiguration qjc = bigQueryService.filterBigQueryConfig(participantCounter.buildParticipantCounterQuery(
      new ParticipantCriteria(request)));
    QueryResult result = bigQueryService.executeQuery(qjc);
    Map<String, Integer> rm = bigQueryService.getResultMapper(result);

    List<FieldValue> row = result.iterateAll().iterator().next();
    return ResponseEntity.ok(bigQueryService.getLong(row, rm.get("count")));
  }

  @Override
  public ResponseEntity<ChartInfoListResponse> getChartInfo(Long cdrVersionId, SearchRequest request) {
    cdrVersionService.setCdrVersion(cdrVersionDao.findOne(cdrVersionId));
    ChartInfoListResponse response = new ChartInfoListResponse();

    QueryJobConfiguration qjc = bigQueryService.filterBigQueryConfig(participantCounter.buildChartInfoCounterQuery(
      new ParticipantCriteria(request)));
    QueryResult result = bigQueryService.executeQuery(qjc);
    Map<String, Integer> rm = bigQueryService.getResultMapper(result);

    for (List<FieldValue> row : result.iterateAll()) {
      response.addItemsItem(new ChartInfo()
        .gender(bigQueryService.getString(row, rm.get("gender")))
        .race(bigQueryService.getString(row, rm.get("race")))
        .ageRange(bigQueryService.getString(row, rm.get("ageRange")))
        .count(bigQueryService.getLong(row, rm.get("count"))));
    }
    return ResponseEntity.ok(response);
  }

  @Override
  public ResponseEntity<CriteriaAttributeListResponse> getCriteriAttributeByConceptId(Long cdrVersionId, Long conceptId) {
    return null;
  }

  @Override
  public ResponseEntity<CriteriaListResponse> getCriteriaById(Long cdrVersionId, Long id) {
    cdrVersionService.setCdrVersion(cdrVersionDao.findOne(cdrVersionId));
    final List<Criteria> criteriaList = criteriaDao.findCriteriaById(id);

    CriteriaListResponse criteriaResponse = new CriteriaListResponse();
    criteriaResponse.setItems(criteriaList.stream().map(TO_CLIENT_CRITERIA).collect(Collectors.toList()));

    return ResponseEntity.ok(criteriaResponse);
  }

  @Override
  public ResponseEntity<CriteriaListResponse> getCriteriaByType(Long cdrVersionId, String type) {
    cdrVersionService.setCdrVersion(cdrVersionDao.findOne(cdrVersionId));
    final List<Criteria> criteriaList = criteriaDao.findCriteriaByType(type);

    CriteriaListResponse criteriaResponse = new CriteriaListResponse();
    criteriaResponse.setItems(criteriaList.stream().map(TO_CLIENT_CRITERIA).collect(Collectors.toList()));

    return ResponseEntity.ok(criteriaResponse);
  }

  @Override
  public ResponseEntity<CriteriaListResponse> getCriteriaTreeQuickSearch(Long cdrVersionId, String type, String value) {
    cdrVersionService.setCdrVersion(cdrVersionDao.findOne(cdrVersionId));
    String nameOrCode = value + "*";
    final List<Criteria> criteriaList = criteriaDao.findCriteriaByTypeAndNameOrCode(type, nameOrCode);

    CriteriaListResponse criteriaResponse = new CriteriaListResponse();
    criteriaResponse.setItems(criteriaList.stream().map(TO_CLIENT_CRITERIA).collect(Collectors.toList()));

    return ResponseEntity.ok(criteriaResponse);
  }

  @Override
  public ResponseEntity<ParticipantDemographics> getParticipantDemographics(Long cdrVersionId) {
    cdrVersionService.setCdrVersion(cdrVersionDao.findOne(cdrVersionId));

    Map<String, Map<Long, String>> concepts = genderRaceEthnicityConceptProvider.get().getConcepts();
    List<ConceptIdName> genderList = concepts.get(ParticipantCohortStatusColumns.GENDER.name()).entrySet().stream()
      .map(e -> new ConceptIdName().conceptId(e.getKey()).conceptName(e.getValue()))
      .collect(Collectors.toList());
    List<ConceptIdName> raceList = concepts.get(ParticipantCohortStatusColumns.RACE.name()).entrySet().stream()
      .map(e -> new ConceptIdName().conceptId(e.getKey()).conceptName(e.getValue()))
      .collect(Collectors.toList());
    List<ConceptIdName> ethnicityList = concepts.get(ParticipantCohortStatusColumns.ETHNICITY.name()).entrySet().stream()
      .map(e -> new ConceptIdName().conceptId(e.getKey()).conceptName(e.getValue()))
      .collect(Collectors.toList());

    ParticipantDemographics participantDemographics =
      new ParticipantDemographics().genderList(genderList).raceList(raceList).ethnicityList(ethnicityList);
    return ResponseEntity.ok(participantDemographics);
  }

}
