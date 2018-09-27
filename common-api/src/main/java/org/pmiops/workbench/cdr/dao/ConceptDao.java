package org.pmiops.workbench.cdr.dao;

import org.pmiops.workbench.cdr.model.Concept;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.CrudRepository;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface ConceptDao extends CrudRepository<Concept, Long> {

    @Query(nativeQuery=true, value="select c.* from concept c join concept_relationship cr on c.concept_id=cr.concept_id_2 " +
            "where cr.concept_id_1=?1 and cr.relationship_id='Maps to' ")
    List<Concept> findStandardConcepts(long concept_id);

    @Query(value="select c.* from concept c "+
            "join concept_relationship rel on " +
            "rel.concept_id_1 = c.concept_id and rel.concept_id_2 = :conceptId and " +
            "rel.relationship_id = 'maps to' where c.concept_id != :conceptId and c.source_count_value > :minCount order " +
            "by c.count_value desc",nativeQuery=true)
    List<Concept> findSourceConcepts(@Param("conceptId") long conceptId,@Param("minCount") Integer minCount);

    @Query(value = "select c.* from concept c " +
            "join concept_relationship rel on rel.concept_id_2 = c.concept_id " +
            "and rel.concept_id_1 = :conceptId and rel.relationship_id = 'maps to' " +
            "where c.concept_id != :conceptId order by c.count_value desc",
            nativeQuery = true)
    List<Concept> findConceptsMapsToParents(@Param("conceptId") long conceptId);

    List<Concept> findByConceptName(String conceptName);

    @Query(value = "select c.concept_id, " +
      "c.concept_name, " +
      "c.domain_id, " +
      "c.vocabulary_id, " +
      "c.concept_class_id, " +
      "c.standard_concept, " +
      "c.concept_code, " +
      "c.count_value, " +
      "c.source_count_value, " +
      "c.prevalence " +
      "from concept c " +
      "where c.vocabulary_id in ('Gender', 'Race', 'Ethnicity')",
      nativeQuery = true)
    List<Concept> findGenderRaceEthnicityFromConcept();

    @Query(value = "select distinct c.conceptId from Concept c left join c.synonyms as cs " +
            "where match(cs.conceptSynonymName,?1) > 0 or match(c.conceptName,?1) > 0")
    List<Long> findConceptSynonyms(String query);

}
