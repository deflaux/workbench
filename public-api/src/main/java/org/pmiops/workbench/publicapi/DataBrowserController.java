package org.pmiops.workbench.publicapi;

import org.pmiops.workbench.cdr.dao.*;
import org.pmiops.workbench.cdr.model.*;
import org.pmiops.workbench.model.ConceptListResponse;
import org.pmiops.workbench.model.ConceptAnalysisListResponse;
import org.pmiops.workbench.model.ConceptAnalysis;
import org.pmiops.workbench.model.DbDomainListResponse;
import org.pmiops.workbench.model.QuestionConceptListResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.pmiops.workbench.model.Domain;
import org.pmiops.workbench.model.StandardConceptFilter;
import org.pmiops.workbench.model.MatchType;
import org.pmiops.workbench.model.SearchConceptsRequest;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.data.domain.Slice;
import javax.persistence.EntityManager;

import com.google.common.collect.ImmutableMultimap;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.Arrays;
import java.util.function.Function;
import java.util.stream.Collectors;

@RestController
public class DataBrowserController implements DataBrowserApiDelegate {

    @Autowired
    private ConceptDao conceptDao;
    @Autowired
    private QuestionConceptDao  questionConceptDao;
    @Autowired
    private AchillesAnalysisDao achillesAnalysisDao;
    @Autowired
    private AchillesResultDao achillesResultDao;
    @Autowired
    private DbDomainDao dbDomainDao;
    @Autowired
    private AchillesResultDistDao achillesResultDistDao;
    @Autowired
    private EntityManager entityManager;

    private ConceptService conceptService;

    public DataBrowserController(ConceptService conceptService, ConceptDao conceptDao, DbDomainDao dbDomainDao, AchillesResultDao achillesResultDao,AchillesAnalysisDao achillesAnalysisDao, AchillesResultDistDao achillesResultDistDao, EntityManager entityManager) {
        this.conceptService = conceptService;
        this.conceptDao = conceptDao;
        this.dbDomainDao = dbDomainDao;
        this.achillesResultDao = achillesResultDao;
        this.achillesAnalysisDao = achillesAnalysisDao;
        this.achillesResultDistDao = achillesResultDistDao;
        this.entityManager = entityManager;
    }


    // TODO: consider putting this in CDM config, fetching it from there
    private static final ImmutableMultimap<Domain, String> DOMAIN_MAP =
            ImmutableMultimap.<Domain, String>builder()
                    .put(Domain.CONDITION, "Condition")
                    .put(Domain.CONDITION, "Condition/Meas")
                    .put(Domain.CONDITION, "Condition/Device")
                    .put(Domain.CONDITION, "Condition/Procedure")
                    .put(Domain.DEVICE, "Device")
                    .put(Domain.DEVICE, "Condition/Device")
                    .put(Domain.DRUG, "Drug")
                    .put(Domain.ETHNICITY, "Ethnicity")
                    .put(Domain.GENDER, "Gender")
                    .put(Domain.MEASUREMENT, "Measurement")
                    .put(Domain.MEASUREMENT, "Meas/Procedure")
                    .put(Domain.OBSERVATION, "Observation")
                    .put(Domain.PROCEDURE, "Procedure")
                    .put(Domain.PROCEDURE, "Meas/Procedure")
                    .put(Domain.PROCEDURE, "Condition/Procedure")
                    .put(Domain.RACE, "Race")
                    .build();

    public static final long PARTICIPANT_COUNT_ANALYSIS_ID = 1;
    public static final long COUNT_ANALYSIS_ID = 3000;
    public static final long GENDER_ANALYSIS_ID = 3101;
    public static final long AGE_ANALYSIS_ID = 3102;

    public static final long RACE_ANALYSIS_ID = 3103;
    public static final long ETHNICITY_ANALYSIS_ID = 3104;

    public static final long MEASUREMENT_DIST_ANALYSIS_ID = 1815;

    public static final long MEASUREMENT_GENDER_ANALYSIS_ID = 1900;
    public static final long MEASUREMENT_AGE_ANALYSIS_ID = 1901;

    public static final long GENDER_ANALYSIS = 2;
    public static final long RACE_ANALYSIS = 4;
    public static final long ETHNICITY_ANALYSIS = 5;

    public static HashMap<Long,ArrayList<String>> conceptSynonymNames = new HashMap<>();

    /**
     * Converter function from backend representation (used with Hibernate) to
     * client representation (generated by Swagger).
     */
    private static final Function<Concept, org.pmiops.workbench.model.Concept>
            TO_CLIENT_CONCEPT =
            new Function<Concept, org.pmiops.workbench.model.Concept>() {
                @Override
                public org.pmiops.workbench.model.Concept apply(Concept concept) {
                    return new org.pmiops.workbench.model.Concept()
                            .conceptId(concept.getConceptId())
                            .conceptName(concept.getConceptName())
                            .standardConcept(concept.getStandardConcept())
                            .conceptCode(concept.getConceptCode())
                            .conceptClassId(concept.getConceptClassId())
                            .vocabularyId(concept.getVocabularyId())
                            .domainId(concept.getDomainId())
                            .countValue(concept.getCountValue())
                            .sourceCountValue(concept.getSourceCountValue())
                            .prevalence(concept.getPrevalence())
                            .conceptSynonyms(conceptSynonymNames.get(concept.getConceptId()));
                }
            };


    /**
     * Converter function from backend representation (used with Hibernate) to
     * client representation (generated by Swagger).
     */
    private static final Function<QuestionConcept, org.pmiops.workbench.model.QuestionConcept>
            TO_CLIENT_QUESTION_CONCEPT =
            new Function<QuestionConcept, org.pmiops.workbench.model.QuestionConcept>() {
                @Override
                public org.pmiops.workbench.model.QuestionConcept apply(QuestionConcept concept) {
                    org.pmiops.workbench.model.Analysis countAnalysis=null;
                    org.pmiops.workbench.model.Analysis genderAnalysis=null;
                    org.pmiops.workbench.model.Analysis ageAnalysis=null;
                    if(concept.getCountAnalysis() != null){
                        countAnalysis = TO_CLIENT_ANALYSIS.apply(concept.getCountAnalysis());
                    }
                    if(concept.getGenderAnalysis() != null){
                        genderAnalysis = TO_CLIENT_ANALYSIS.apply(concept.getGenderAnalysis());
                    }
                    if(concept.getAgeAnalysis() != null){
                        ageAnalysis = TO_CLIENT_ANALYSIS.apply(concept.getAgeAnalysis());
                    }


                    return new org.pmiops.workbench.model.QuestionConcept()
                            .conceptId(concept.getConceptId())
                            .conceptName(concept.getConceptName())
                            .conceptCode(concept.getConceptCode())
                            .domainId(concept.getDomainId())
                            .countValue(concept.getCountValue())
                            .prevalence(concept.getPrevalence())
                            .countAnalysis(countAnalysis)
                            .genderAnalysis(genderAnalysis)
                            .ageAnalysis(ageAnalysis);
                }
            };

    /**
     * Converter function from backend representation (used with Hibernate) to
     * client representation (generated by Swagger).
     */
    private static final Function<AchillesAnalysis, org.pmiops.workbench.model.Analysis>
            TO_CLIENT_ANALYSIS =
            new Function<AchillesAnalysis, org.pmiops.workbench.model.Analysis>() {
                @Override
                public org.pmiops.workbench.model.Analysis apply(AchillesAnalysis cdr) {
                    List<org.pmiops.workbench.model.AchillesResult> results = new ArrayList<>();
                    if (!cdr.getResults().isEmpty()) {
                        results = cdr.getResults().stream().map(TO_CLIENT_ACHILLES_RESULT).collect(Collectors.toList());
                    }

                    List<org.pmiops.workbench.model.AchillesResultDist> distResults = new ArrayList<>();
                    if (!cdr.getDistResults().isEmpty()) {
                        distResults = cdr.getDistResults().stream().map(TO_CLIENT_ACHILLES_RESULT_DIST).collect(Collectors.toList());
                    }

                    return new org.pmiops.workbench.model.Analysis()
                            .analysisId(cdr.getAnalysisId())
                            .analysisName(cdr.getAnalysisName())
                            .stratum1Name(cdr.getStratum1Name())
                            .stratum2Name(cdr.getStratum2Name())
                            .stratum3Name(cdr.getStratum3Name())
                            .stratum4Name(cdr.getStratum4Name())
                            .stratum5Name(cdr.getStratum5Name())
                            .chartType(cdr.getChartType())
                            .dataType(cdr.getDataType())
                            .results(results)
                            .distResults(distResults);

                }
            };

    /**
     * Converter function from backend representation (used with Hibernate) to
     * client representation (generated by Swagger).
     */
    private static final Function<DbDomain, org.pmiops.workbench.model.DbDomain>
            TO_CLIENT_DBDOMAIN =
            new Function<DbDomain, org.pmiops.workbench.model.DbDomain>() {
                @Override
                public org.pmiops.workbench.model.DbDomain apply(DbDomain cdr) {
                    return new org.pmiops.workbench.model.DbDomain()
                            .domainId(cdr.getDomainId())
                            .domainDisplay(cdr.getDomainDisplay())
                            .domainDesc(cdr.getDomainDesc())
                            .dbType(cdr.getDbType())
                            .domainRoute(cdr.getDomainRoute())
                            .conceptId(cdr.getConceptId())
                            .countValue(cdr.getCountValue())
                            .participantCount(cdr.getParticipantCount());
                }
            };

    /**
     * Converter function from backend representation (used with Hibernate) to
     * client representation (generated by Swagger).
     */
    private static final Function<ConceptAnalysis, ConceptAnalysis>
            TO_CLIENT_CONCEPTANALYSIS=
            new Function<ConceptAnalysis, ConceptAnalysis>() {
                @Override
                public ConceptAnalysis apply(ConceptAnalysis ca) {
                    return new ConceptAnalysis()
                            .conceptId(ca.getConceptId())
                            .genderAnalysis(ca.getGenderAnalysis())
                            .ageAnalysis(ca.getAgeAnalysis())
                            .raceAnalysis(ca.getRaceAnalysis())
                            .ethnicityAnalysis(ca.getEthnicityAnalysis())
                            .measurementValueGenderAnalysis(ca.getMeasurementValueGenderAnalysis())
                            .measurementValueAgeAnalysis(ca.getMeasurementValueAgeAnalysis())
                            .measurementDistributionAnalysis(ca.getMeasurementDistributionAnalysis())
                            .unitName(ca.getUnitName());
                }
            };


    /**
     * Converter function from backend representation (used with Hibernate) to
     * client representation (generated by Swagger).
     */
    private static final Function<AchillesResult, org.pmiops.workbench.model.AchillesResult>
            TO_CLIENT_ACHILLES_RESULT =
            new Function<AchillesResult, org.pmiops.workbench.model.AchillesResult>() {
                @Override
                public org.pmiops.workbench.model.AchillesResult apply(AchillesResult o) {

                    return new org.pmiops.workbench.model.AchillesResult()
                            .id(o.getId())
                            .analysisId(o.getAnalysisId())
                            .stratum1(o.getStratum1())
                            .stratum2(o.getStratum2())
                            .stratum3(o.getStratum3())
                            .stratum4(o.getStratum4())
                            .stratum5(o.getStratum5())
                            .analysisStratumName(o.getAnalysisStratumName())
                            .countValue(o.getCountValue())
                            .sourceCountValue(o.getSourceCountValue());
                }
            };


    /**
     * Converter function from backend representation (used with Hibernate) to
     * client representation (generated by Swagger).
     */
    private static final Function<AchillesResultDist, org.pmiops.workbench.model.AchillesResultDist>
            TO_CLIENT_ACHILLES_RESULT_DIST =
            new Function<AchillesResultDist, org.pmiops.workbench.model.AchillesResultDist>() {
                @Override
                public org.pmiops.workbench.model.AchillesResultDist apply(AchillesResultDist o) {

                    return new org.pmiops.workbench.model.AchillesResultDist()
                            .id(o.getId())
                            .analysisId(o.getAnalysisId())
                            .stratum1(o.getStratum1())
                            .stratum2(o.getStratum2())
                            .stratum3(o.getStratum3())
                            .stratum4(o.getStratum4())
                            .stratum5(o.getStratum5())
                            .countValue(o.getCountValue())
                            .minValue(o.getMinValue())
                            .maxValue(o.getMaxValue())
                            .avgValue(o.getAvgValue())
                            .stdevValue(o.getStdevValue())
                            .medianValue(o.getMedianValue())
                            .p10Value(o.getP10Value())
                            .p25Value(o.getP25Value())
                            .p75Value(o.getP75Value())
                            .p90Value(o.getP90Value());
                }
            };


    @Override
    public ResponseEntity<DbDomainListResponse> getDomainFilters() {
        List<DbDomain> domains=dbDomainDao.findByDbType("domain_filter");
        DbDomainListResponse resp=new DbDomainListResponse();
        resp.setItems(domains.stream().map(TO_CLIENT_DBDOMAIN).collect(Collectors.toList()));
        return ResponseEntity.ok(resp);
    }

    @Override
    public ResponseEntity<DbDomainListResponse> getSurveyList() {
        List<DbDomain> domains=dbDomainDao.findByDbTypeAndConceptIdNot("survey",0L);
        DbDomainListResponse resp=new DbDomainListResponse();
        resp.setItems(domains.stream().map(TO_CLIENT_DBDOMAIN).collect(Collectors.toList()));
        return ResponseEntity.ok(resp);
    }

    @Override
    public ResponseEntity<DbDomainListResponse> getDomainSearchResults(String query){

        String keyword = ConceptService.modifyMultipleMatchKeyword(query);
        List<DbDomain> domains = new ArrayList<>();
        domains = dbDomainDao.findDomainSearchResults(keyword,query);
        DbDomainListResponse resp = new DbDomainListResponse();
        resp.setItems(domains.stream().map(TO_CLIENT_DBDOMAIN).collect(Collectors.toList()));
        return ResponseEntity.ok(resp);
    }

    @Override
    public ResponseEntity<ConceptListResponse> searchConcepts(SearchConceptsRequest searchConceptsRequest){

        Integer maxResults = searchConceptsRequest.getMaxResults();
        if(maxResults == null || maxResults == 0){
            maxResults = Integer.MAX_VALUE;
        }

        Integer minCount = searchConceptsRequest.getMinCount();
        if(minCount == null){
            minCount = 1;
        }

        StandardConceptFilter standardConceptFilter = searchConceptsRequest.getStandardConceptFilter();


        if(searchConceptsRequest.getQuery() == null || searchConceptsRequest.getQuery().isEmpty()){
            if(standardConceptFilter == null || standardConceptFilter == StandardConceptFilter.STANDARD_OR_CODE_ID_MATCH){
                standardConceptFilter = StandardConceptFilter.STANDARD_CONCEPTS;
            }
        }else{
            if(standardConceptFilter == null){
                standardConceptFilter = StandardConceptFilter.STANDARD_OR_CODE_ID_MATCH;
            }
        }

        List<String> domainIds = null;
        if (searchConceptsRequest.getDomain() != null) {
            domainIds = DOMAIN_MAP.get(searchConceptsRequest.getDomain()).asList();
        }

        ConceptService.StandardConceptFilter convertedConceptFilter = ConceptService.StandardConceptFilter.valueOf(standardConceptFilter.name());


        Slice<Concept> concepts = null;
        concepts = conceptService.searchConcepts(searchConceptsRequest.getQuery(), convertedConceptFilter,
                searchConceptsRequest.getVocabularyIds(), domainIds, maxResults, minCount);
        ConceptListResponse response = new ConceptListResponse();


        for(Concept con : concepts.getContent()){
            String conceptCode = con.getConceptCode();
            String conceptId = String.valueOf(con.getConceptId());

            ArrayList<String> conceptSynonymNames = new ArrayList<>();

            for(ConceptSynonym conceptSynonym:con.getSynonyms()){
                if(!conceptSynonymNames.contains(conceptSynonym.getConceptSynonymName()) && !con.getConceptName().equals(conceptSynonym.getConceptSynonymName())){
                    conceptSynonymNames.add(conceptSynonym.getConceptSynonymName());
                    }
            }


            this.conceptSynonymNames.put(con.getConceptId(),conceptSynonymNames);

            if((con.getStandardConcept() == null || !con.getStandardConcept().equals("S") ) && (searchConceptsRequest.getQuery().equals(conceptCode) || searchConceptsRequest.getQuery().equals(conceptId))){
                response.setMatchType(conceptCode.equals(searchConceptsRequest.getQuery()) ? MatchType.CODE : MatchType.ID );

                List<Concept> std_concepts = conceptDao.findStandardConcepts(con.getConceptId());
                response.setStandardConcepts(std_concepts.stream().map(TO_CLIENT_CONCEPT).collect(Collectors.toList()));
            }

        }

        if(response.getMatchType() == null && response.getStandardConcepts() == null){
            response.setMatchType(MatchType.NAME);
        }

        response.setItems(concepts.getContent().stream().map(TO_CLIENT_CONCEPT).collect(Collectors.toList()));
        return ResponseEntity.ok(response);
    }

    @Override
    public ResponseEntity<DbDomainListResponse> getDomainTotals(){
        List<DbDomain> domains = dbDomainDao.findDomainTotals();
        List<Concept> concepts = conceptDao.findDbDomainParticpantCounts();
        DbDomain.mapConceptCounts(concepts);
        for(DbDomain dbd : domains){
            if(dbd.getParticipantCount() == 0){
                Long participantCount = DbDomain.conceptCountMap.get(dbd.getConceptId());
                if(participantCount != null){
                    dbd.setParticipantCount(participantCount);
                }
            }
        }
        DbDomainListResponse resp=new DbDomainListResponse();
        resp.setItems(domains.stream().map(TO_CLIENT_DBDOMAIN).collect(Collectors.toList()));
        return ResponseEntity.ok(resp);
    }

    @Override
    public ResponseEntity<org.pmiops.workbench.model.Analysis> getGenderAnalysis(){
        AchillesAnalysis genderAnalysis = achillesAnalysisDao.findAnalysisById(GENDER_ANALYSIS);
        for(AchillesResult ar: genderAnalysis.getResults()){
            String analysisStratumName =ar.getAnalysisStratumName();
            if (analysisStratumName == null || analysisStratumName.equals("")) {
                ar.setAnalysisStratumName(QuestionConcept.genderStratumNameMap.get(ar.getStratum1()));
            }
        }
        return ResponseEntity.ok(TO_CLIENT_ANALYSIS.apply(genderAnalysis));
    }

    @Override
    public ResponseEntity<org.pmiops.workbench.model.Analysis> getRaceAnalysis(){
        AchillesAnalysis raceAnalysis = achillesAnalysisDao.findAnalysisById(RACE_ANALYSIS);
        for(AchillesResult ar: raceAnalysis.getResults()){
            String analysisStratumName =ar.getAnalysisStratumName();
            if (analysisStratumName == null || analysisStratumName.equals("")) {
                ar.setAnalysisStratumName(QuestionConcept.raceStratumNameMap.get(ar.getStratum1()));
            }
        }
        return ResponseEntity.ok(TO_CLIENT_ANALYSIS.apply(raceAnalysis));
    }

    @Override
    public ResponseEntity<org.pmiops.workbench.model.Analysis> getEthnicityAnalysis(){
        AchillesAnalysis ethnicityAnalysis = achillesAnalysisDao.findAnalysisById(ETHNICITY_ANALYSIS);
        for(AchillesResult ar: ethnicityAnalysis.getResults()){
            String analysisStratumName =ar.getAnalysisStratumName();
            if (analysisStratumName == null || analysisStratumName.equals("")) {
                ar.setAnalysisStratumName(QuestionConcept.ethnicityStratumNameMap.get(ar.getStratum1()));
            }
        }
        return ResponseEntity.ok(TO_CLIENT_ANALYSIS.apply(ethnicityAnalysis));
    }

    @Override
    public ResponseEntity<QuestionConceptListResponse> getSurveyResults(String surveyConceptId) {
        /* Set up the age and gender names */
        // Too slow and concept names wrong so we hardcode list
        // List<Concept> genders = conceptDao.findByConceptClassId("Gender");

        long longSurveyConceptId = Long.parseLong(surveyConceptId);

        // Get questions for survey
        List<QuestionConcept> questions = questionConceptDao.findSurveyQuestions(longSurveyConceptId);

        // Get survey definition
        QuestionConceptListResponse resp = new QuestionConceptListResponse();
        DbDomain survey = dbDomainDao.findByConceptId(longSurveyConceptId);
        resp.setSurvey(TO_CLIENT_DBDOMAIN.apply(survey));
        // Get all analyses for question list and put the analyses on the question objects
        if (!questions.isEmpty()) {
            // Put ids in array for query to get all results at once
            List<String> qlist = new ArrayList();
            for (QuestionConcept q : questions) {
                qlist.add(String.valueOf(q.getConceptId()));
            }

            List<AchillesAnalysis> analyses = achillesAnalysisDao.findSurveyAnalysisResults(surveyConceptId, qlist);
            QuestionConcept.mapAnalysesToQuestions(questions, analyses);
        }

        resp.setItems(questions.stream().map(TO_CLIENT_QUESTION_CONCEPT).collect(Collectors.toList()));
        return ResponseEntity.ok(resp);
    }

    @Override
    public ResponseEntity<ConceptAnalysisListResponse> getConceptAnalysisResults(List<String> conceptIds){
        ConceptAnalysisListResponse resp=new ConceptAnalysisListResponse();
        List<ConceptAnalysis> conceptAnalysisList=new ArrayList<>();
        List<Long> analysisIds  = new ArrayList<>();
        analysisIds.add(GENDER_ANALYSIS_ID);
        analysisIds.add(AGE_ANALYSIS_ID);
        analysisIds.add(RACE_ANALYSIS_ID);
        analysisIds.add(COUNT_ANALYSIS_ID);
        analysisIds.add(ETHNICITY_ANALYSIS_ID);
        analysisIds.add(MEASUREMENT_GENDER_ANALYSIS_ID);
        analysisIds.add(MEASUREMENT_AGE_ANALYSIS_ID);
        analysisIds.add(MEASUREMENT_DIST_ANALYSIS_ID);

        for(String conceptId: conceptIds){
            ConceptAnalysis conceptAnalysis=new ConceptAnalysis();

            boolean isMeasurement = false;

            List<AchillesAnalysis> analysisList = achillesAnalysisDao.findConceptAnalysisResults(conceptId,analysisIds);

            HashMap<Long, AchillesAnalysis> analysisHashMap = new HashMap<>();
            for(AchillesAnalysis aa: analysisList){
                this.entityManager.detach(aa);
                analysisHashMap.put(aa.getAnalysisId(), aa);
            }

            AchillesAnalysis analysis = analysisHashMap.get(COUNT_ANALYSIS_ID);
            String unitName = null;
            if(analysis != null){
                for(AchillesResult results: analysis.getResults()){
                    unitName = results.getStratum4();
                }
            }

            conceptAnalysis.setConceptId(conceptId);
            Iterator it = analysisHashMap.entrySet().iterator();
            while(it.hasNext()) {
                Map.Entry pair = (Map.Entry)it.next();
                Long analysisId = (Long)pair.getKey();
                AchillesAnalysis aa = (AchillesAnalysis)pair.getValue();
                conceptAnalysis.setUnitName(unitName);
                if(analysisId == GENDER_ANALYSIS_ID){
                    for(AchillesResult ar: aa.getResults()){
                        String analysisStratumName =ar.getAnalysisStratumName();
                        if (analysisStratumName == null || analysisStratumName.equals("")) {
                            ar.setAnalysisStratumName(QuestionConcept.genderStratumNameMap.get(ar.getStratum2()));
                        }
                    }
                    conceptAnalysis.setGenderAnalysis(TO_CLIENT_ANALYSIS.apply(aa));
                }else if(analysisId == AGE_ANALYSIS_ID){
                    Set<String> uniqueAgeDeciles = new TreeSet<String>();
                    for(AchillesResult ar: aa.getResults()){
                        String analysisStratumName=ar.getAnalysisStratumName();
                        uniqueAgeDeciles.add(ar.getStratum2());
                        if (analysisStratumName == null || analysisStratumName.equals("")) {
                            ar.setAnalysisStratumName(QuestionConcept.ageStratumNameMap.get(ar.getStratum2()));
                        }
                    }
                    if(uniqueAgeDeciles.size() < 7){
                        Set<String> completeAgeDeciles = new TreeSet<String>(Arrays.asList(new String[] {"2", "3", "4", "5", "6", "7", "8"}));
                        completeAgeDeciles.removeAll(uniqueAgeDeciles);
                        for(String missingAgeDecile: completeAgeDeciles){
                            AchillesResult missingResult = new AchillesResult();
                            missingResult.setAnalysisId(AGE_ANALYSIS_ID);
                            missingResult.setStratum1(conceptId);
                            missingResult.setStratum2(missingAgeDecile);
                            missingResult.setAnalysisStratumName(QuestionConcept.ageStratumNameMap.get(missingAgeDecile));
                            missingResult.setCountValue(0L);
                            missingResult.setSourceCountValue(0L);
                            aa.getResults().add(missingResult);
                        }
                    }
                    conceptAnalysis.setAgeAnalysis(TO_CLIENT_ANALYSIS.apply(aa));
                }else if(analysisId == RACE_ANALYSIS_ID){
                    for(AchillesResult ar: aa.getResults()){
                        String analysisStratumName=ar.getAnalysisStratumName();
                        if (analysisStratumName == null || analysisStratumName.equals("")) {
                            ar.setAnalysisStratumName(QuestionConcept.raceStratumNameMap.get(ar.getStratum2()));
                        }
                    }
                    conceptAnalysis.setRaceAnalysis(TO_CLIENT_ANALYSIS.apply(aa));
                }else if(analysisId == ETHNICITY_ANALYSIS_ID){
                    for(AchillesResult ar: aa.getResults()){
                        String analysisStratumName=ar.getAnalysisStratumName();
                        if (analysisStratumName == null || analysisStratumName.equals("")) {
                            ar.setAnalysisStratumName(QuestionConcept.ethnicityStratumNameMap.get(ar.getStratum2()));
                        }
                    }
                    conceptAnalysis.setEthnicityAnalysis(TO_CLIENT_ANALYSIS.apply(aa));
                }else if(analysisId == MEASUREMENT_GENDER_ANALYSIS_ID){

                    isMeasurement = true;


                    for(AchillesResult ar: aa.getResults()){
                        String analysisStratumName=ar.getAnalysisStratumName();
                        if (analysisStratumName == null || analysisStratumName.equals("")) {
                            ar.setAnalysisStratumName(QuestionConcept.genderStratumNameMap.get(ar.getStratum2()));
                        }
                    }


                    conceptAnalysis.setMeasurementValueGenderAnalysis(TO_CLIENT_ANALYSIS.apply(aa));

                }else if(analysisId == MEASUREMENT_AGE_ANALYSIS_ID){
                    isMeasurement = true;

                    for(AchillesResult ar: aa.getResults()){
                        String analysisStratumName=ar.getAnalysisStratumName();
                        if (analysisStratumName == null || analysisStratumName.equals("")) {
                            ar.setAnalysisStratumName(QuestionConcept.ageStratumNameMap.get(ar.getStratum2()));
                        }
                    }
                    conceptAnalysis.setMeasurementValueAgeAnalysis(TO_CLIENT_ANALYSIS.apply(aa));
                }
            }

            if(isMeasurement){
                AchillesAnalysis measurementDistAnalysis = achillesAnalysisDao.findAnalysisById(MEASUREMENT_DIST_ANALYSIS_ID);
                List<AchillesResultDist> achillesResultDistList = achillesResultDistDao.fetchConceptDistResults(MEASUREMENT_DIST_ANALYSIS_ID,conceptId);
                measurementDistAnalysis.setDistResults(achillesResultDistList);
                conceptAnalysis.setMeasurementDistributionAnalysis(TO_CLIENT_ANALYSIS.apply(measurementDistAnalysis));
            }
            conceptAnalysisList.add(conceptAnalysis);
        }

        resp.setItems(conceptAnalysisList.stream().map(TO_CLIENT_CONCEPTANALYSIS).collect(Collectors.toList()));
        return ResponseEntity.ok(resp);
    }


    /**
     * This method gets concepts with maps to relationship in concept relationship table
     *
     * @param conceptId
     * @return
     */
    @Override
    public ResponseEntity<ConceptListResponse> getSourceConcepts(Long conceptId,Integer minCount) {
        Integer count=minCount;
        if(count == null){
            count = 0;
        }
        List<Concept> conceptList = conceptDao.findSourceConcepts(conceptId,count);
        ConceptListResponse resp = new ConceptListResponse();
        resp.setItems(conceptList.stream().map(TO_CLIENT_CONCEPT).collect(Collectors.toList()));
        return ResponseEntity.ok(resp);
    }

    /**
     * This method gets concepts with maps to relationship in concept relationship table
     *
     * @param conceptId
     * @return
     */
    @Override
    public ResponseEntity<ConceptListResponse> getParentConcepts(Long conceptId) {
        List<Concept> conceptList = conceptDao.findConceptsMapsToParents(conceptId);
        ConceptListResponse resp = new ConceptListResponse();
        resp.setItems(conceptList.stream().map(TO_CLIENT_CONCEPT).collect(Collectors.toList()));
        return ResponseEntity.ok(resp);
    }

    @Override
    public ResponseEntity<org.pmiops.workbench.model.AchillesResult> getParticipantCount() {
        AchillesResult result = achillesResultDao.findAchillesResultByAnalysisId(PARTICIPANT_COUNT_ANALYSIS_ID);
        return ResponseEntity.ok(TO_CLIENT_ACHILLES_RESULT.apply(result));
    }

    @Override
    public ResponseEntity<DbDomainListResponse> getDbDomains() {
        List<DbDomain> resultList = dbDomainDao.findByConceptIdNotNull();
        DbDomainListResponse resp = new DbDomainListResponse();
        resp.setItems(resultList.stream().map(TO_CLIENT_DBDOMAIN).collect(Collectors.toList()));
        return ResponseEntity.ok(resp);
    }


}
