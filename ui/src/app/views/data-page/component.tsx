import {Component} from '@angular/core';

import * as React from 'react';

import {CardButton, TabButton} from 'app/components/buttons';
import {FadeBox} from 'app/components/containers';
import {ClrIcon} from 'app/components/icons';
import {SpinnerOverlay} from 'app/components/spinners';
import {cohortsApi, conceptsApi, conceptSetsApi} from 'app/services/swagger-fetch-clients';
import {WorkspaceData} from 'app/services/workspace-storage.service';
import {ReactWrapperBase, withCurrentWorkspace} from 'app/utils';
import {navigate} from 'app/utils/navigation';
import {
  convertToResources,
  mapAndFilterResourceList,
  ResourceType
} from 'app/utils/resourceActionsReact';
import {CreateConceptSetModal} from 'app/views/conceptset-create-modal/component';
import {ResourceCard} from 'app/views/resource-card/component';
import {DomainInfo, RecentResource, WorkspaceAccessLevel} from 'generated/fetch';

const styles = {
  cardButtonArea: {
    display: 'flex',
    alignItems: 'center',
    width: '100%'
  },
  cardHeader: {
    display: 'flex',
    alignItems: 'baseline'
  },
  resourceTypeButton: {
    width: '33%',
    justifyContent: 'flex-start',
    maxWidth: 'none',
    margin: '1.9rem 1rem 0 0'
  },
  resourceTypeButtonLast: {
    marginRight: '0rem'
  },
  cardHeaderText: {
    color: '#2691D0',
    fontSize: '20px',
    marginRight: '0.5rem',
    marginTop: '0.5rem'
  },
  cardText: {
    color: '#000000',
    fontSize: '14px',
    lineHeight: '22px'
  },
  tabContainer: {
    display: 'flex',
    justifyContent: 'flex-start',
    alignItems: 'center',
    width: '100%',
    marginBottom: '0.5rem'
  }
};

enum Tabs {
  SHOWALL = 'SHOW ALL',
  DATASETS = 'DATASETS',
  COHORTS = 'COHORTS',
  CONCEPTSETS = 'CONCEPT SETS'
}

const placeholderText = `Littera gothica quam nunc
  putamus parum claram anteposuerit litterarum formas humanitatis per. In
  iis qui facit eorum claritatem Investigationes demonstraverunt lectores
  legere me lius quod ii legunt.`;

export const DataPage = withCurrentWorkspace()(class extends React.Component<
  {workspace: WorkspaceData},
  {activeTab: Tabs, resourceList: RecentResource[], isLoading: boolean,
    creatingConceptSet: boolean, conceptDomainList: DomainInfo[]}> {

  constructor(props) {
    super(props);
    this.state = {
      activeTab: Tabs.SHOWALL,
      resourceList: [],
      isLoading: true,
      creatingConceptSet: false,
      conceptDomainList: undefined
    };
  }

  componentDidMount() {
    const {namespace, id} = this.props.workspace;
    this.loadResources();
    conceptsApi().getDomainInfo(namespace, id).then((response) => {
      this.setState({conceptDomainList: response.items});
    });
  }

  async loadResources() {
    try {
      const {namespace, id, accessLevel} = this.props.workspace;

      this.setState({
        isLoading: true
      });
      const [cohorts, conceptSets] = await Promise.all([
        cohortsApi().getCohortsInWorkspace(namespace, id),
        conceptSetsApi().getConceptSetsInWorkspace(namespace, id),
        // TODO: Load datasets
      ]);
      let list: RecentResource[] = [];
      list = list.concat(convertToResources(cohorts.items, namespace,
        id, accessLevel as unknown as WorkspaceAccessLevel, ResourceType.COHORT));
      list = list.concat(convertToResources(conceptSets.items, namespace,
        id, accessLevel as unknown as WorkspaceAccessLevel, ResourceType.CONCEPT_SET));
      this.setState({
        resourceList: list
      });
    } catch (error) {
      console.log(error);
    } finally {
      this.setState({
        isLoading: false
      });
    }
  }

  render() {
    const {namespace, id} = this.props.workspace;
    const {activeTab, isLoading, resourceList, creatingConceptSet, conceptDomainList} = this.state;
    const filteredList = resourceList.filter((resource) => {
      if (activeTab === Tabs.SHOWALL) {
        return true;
      } else if (activeTab === Tabs.COHORTS) {
        return resource.cohort;
      } else if (activeTab === Tabs.CONCEPTSETS) {
        return resource.conceptSet;
      } else if (activeTab === Tabs.DATASETS) {
        // TODO: Add datasets
        return false;
      }
    });
    return <React.Fragment>
      <FadeBox style={{marginTop: '1rem'}}>
        <h2 style={{marginTop: 0}}>Data</h2>
        <div style={{color: '#000000', fontSize: '14px'}}>{placeholderText}</div>
        <div style={styles.cardButtonArea}>
          <CardButton style={styles.resourceTypeButton} onClick={() => {
            navigate(['workspaces', namespace, id, 'data', 'datasets']);
          }}>
            <div style={styles.cardHeader}>
              <h2 style={styles.cardHeaderText}>Datasets</h2>
              <ClrIcon shape='plus-circle' class='is-solid' size={18} style={{marginTop: 5}}/>
            </div>
            <div style={styles.cardText}>
              {placeholderText}
            </div>
          </CardButton>
          <CardButton style={styles.resourceTypeButton} onClick={() => {
            navigate(['workspaces', namespace, id,  'cohorts', 'build']);
          }}>
            <div style={styles.cardHeader}>
              <h2 style={styles.cardHeaderText}>Cohorts</h2>
              <ClrIcon shape='plus-circle' class='is-solid' size={18} style={{marginTop: 5}}/>
            </div>
            <div style={styles.cardText}>
              {placeholderText}
            </div>
          </CardButton>
          <CardButton style={{...styles.resourceTypeButton, ...styles.resourceTypeButtonLast}}
                      onClick={() => {
                        this.setState({creatingConceptSet: true});
                      }}>
            <div style={styles.cardHeader}>
              <h2 style={styles.cardHeaderText}>Concept Sets</h2>
              <ClrIcon shape='plus-circle' class='is-solid' size={18} style={{marginTop: 5}}/>
            </div>
            <div style={styles.cardText}>
              {placeholderText}
            </div>
          </CardButton>
        </div>
      </FadeBox>
      <FadeBox style={{marginTop: '1rem'}}>
        <div style={styles.tabContainer}>
          <h2 style={{margin: 0, color: '#2F2E7E', fontSize: '16px', fontWeight: 600}}>Show:</h2>
          <TabButton active={activeTab === Tabs.SHOWALL} onClick={() => {
            this.setState({
              activeTab: Tabs.SHOWALL
            });
          }}>Show All</TabButton>
          <TabButton active={activeTab === Tabs.DATASETS} onClick={() => {
            this.setState({
              activeTab: Tabs.DATASETS
            });
          }}>Datasets</TabButton>
          <TabButton active={activeTab === Tabs.COHORTS} onClick={() => {
            this.setState({
              activeTab: Tabs.COHORTS
            });
          }} data-test-id='view-only-cohorts'>Cohorts</TabButton>
          <TabButton active={activeTab === Tabs.CONCEPTSETS} onClick={() => {
            this.setState({
              activeTab: Tabs.CONCEPTSETS
            });
          }} data-test-id='view-only-concept-sets'>Concept Sets</TabButton>
        </div>
        <div style={{
          borderBottom: '1px solid #525A65',
          marginLeft: '-1rem',
          marginRight: '-1rem',
          opacity: 0.24
        }}>
        </div>
        <div style={{
          marginBottom: '1rem',
          display: 'flex',
          flexWrap: 'wrap',
          position: 'relative',
          minHeight: 247,
          padding: '0 0.5rem'
        }}>
          {filteredList.map((resource: RecentResource, index: number) => {
            return <ResourceCard key={index}
                                 resourceCard={resource}
                                 onUpdate={() => this.loadResources()}
            />;
          })}
          {isLoading && <SpinnerOverlay></SpinnerOverlay>}
        </div>
      </FadeBox>
      {creatingConceptSet &&
      <CreateConceptSetModal onCreate={() => {
        this.loadResources().then(() => {
          this.setState({creatingConceptSet: false});
        });
      }}
      onClose={() => {
        this.setState({creatingConceptSet: false});
      }}
      conceptDomainList={conceptDomainList}
      existingConceptSets={mapAndFilterResourceList(resourceList, 'conceptSet')}/>}
    </React.Fragment>;
  }
});

@Component({
  template: '<div #root></div>'
})
export class DataPageComponent extends ReactWrapperBase {
  constructor() {
    super(DataPage, []);
  }
}
