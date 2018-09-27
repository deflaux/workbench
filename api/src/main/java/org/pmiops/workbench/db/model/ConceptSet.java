package org.pmiops.workbench.db.model;


import java.sql.Timestamp;
import java.util.HashSet;
import java.util.Set;
import javax.persistence.CollectionTable;
import javax.persistence.Column;
import javax.persistence.ElementCollection;
import javax.persistence.Entity;
import javax.persistence.FetchType;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.ManyToOne;
import javax.persistence.Table;
import javax.persistence.Transient;
import javax.persistence.Version;
import org.pmiops.workbench.model.Domain;

@Entity
@Table(name = "concept_set")
public class ConceptSet {

  private long conceptSetId;
  private int version;
  private String name;
  private short domain;
  private String description;
  private long workspaceId;
  private User creator;
  private Timestamp creationTime;
  private Timestamp lastModifiedTime;
  private Set<Long> conceptIds = new HashSet<Long>();

  public ConceptSet() {}

  public ConceptSet(ConceptSet cs) {
    setDescription(cs.getDescription());
    setName(cs.getName());
    setDomain(cs.getDomain());
    setCreator(cs.getCreator());
    setWorkspaceId(cs.getWorkspaceId());
    setCreationTime(cs.getCreationTime());
    setLastModifiedTime(cs.getLastModifiedTime());
  }

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  @Column(name = "concept_set_id")
  public long getConceptSetId() {
    return conceptSetId;
  }

  public void setConceptSetId(long conceptSetId) {
    this.conceptSetId = conceptSetId;
  }

  @Version
  @Column(name = "version")
  public int getVersion() {
    return version;
  }

  public void setVersion(int version) { this.version = version; }

  @Column(name = "name")
  public String getName() {
    return name;
  }

  public void setName(String name) {
    this.name = name;
  }

  @Column(name = "domain")
  public short getDomain() {
    return domain;
  }

  public void setDomain(short domain) {
    this.domain = domain;
  }

  @Transient
  public Domain getDomainEnum() {
    return CommonStorageEnums.domainFromStorage(domain);
  }

  public void setDomainEnum(Domain domain) {
    this.domain = CommonStorageEnums.domainToStorage(domain);
  }

  @Column(name = "description")
  public String getDescription() {
    return description;
  }

  public void setDescription(String description) {
    this.description = description;
  }

  @Column(name = "workspace_id")
  public long getWorkspaceId() {
    return workspaceId;
  }

  public void setWorkspaceId(long workspaceId) {
    this.workspaceId = workspaceId;
  }

  @ManyToOne
  @JoinColumn(name = "creator_id")
  public User getCreator() {
    return creator;
  }

  public void setCreator(User creator) {
    this.creator = creator;
  }

  @Column(name = "creation_time")
  public Timestamp getCreationTime() {
    return creationTime;
  }

  public void setCreationTime(Timestamp creationTime) {
    this.creationTime = creationTime;
  }

  @Column(name = "last_modified_time")
  public Timestamp getLastModifiedTime() {
    return lastModifiedTime;
  }

  public void setLastModifiedTime(Timestamp lastModifiedTime) {
    this.lastModifiedTime = lastModifiedTime;
  }

  @ElementCollection(fetch = FetchType.EAGER)
  @CollectionTable(name = "concept_set_concept_id", joinColumns = @JoinColumn(name = "concept_set_id"))
  @Column(name = "concept_id")
  public Set<Long> getConceptIds() {
    return conceptIds;
  }

  public void setConceptIds(Set<Long> conceptIds) {
    this.conceptIds = conceptIds;
  }
}
