package org.pmiops.workbench.cdr.dao;

import java.util.List;
import org.pmiops.workbench.cdr.model.ConceptSynonym;
import org.springframework.data.repository.CrudRepository;

// NOTE: This class and ConceptSynonym exist only to make CriteriaDao work in tests;
// if we stop using concept_synonym there at some point we can get rid of them.
public interface ConceptSynonymDao extends CrudRepository<ConceptSynonym, Long> {

  List<ConceptSynonym> findByConceptIdIn(List<Long> conceptIds);
}
