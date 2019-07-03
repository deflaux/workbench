import {Component} from '@angular/core';

import * as React from 'react';

import {CardButton, TabButton} from 'app/components/buttons';
import {FadeBox} from 'app/components/containers';
import {ClrIcon} from 'app/components/icons';
import {TooltipTrigger} from 'app/components/popups';
import {SpinnerOverlay} from 'app/components/spinners';
import {cohortsApi, conceptSetsApi, dataSetApi} from 'app/services/swagger-fetch-clients';
import colors, {colorWithWhiteness} from 'app/styles/colors';
import {ReactWrapperBase, withCurrentWorkspace} from 'app/utils';
import {navigate} from 'app/utils/navigation';
import {
  convertToResources,
  ResourceType
} from 'app/utils/resourceActionsReact';
import {WorkspaceData} from 'app/utils/workspace-data';
import {ResourceCard} from 'app/views/resource-card';
import {RecentResource, WorkspaceAccessLevel} from 'generated/fetch';

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
    margin: '1.9rem 1rem 0 0',
    minHeight: '325px',
    maxHeight: '325px'
  },
  resourceTypeButtonLast: {
    marginRight: '0rem'
  },
  cardHeaderText: (disabled) => {
    return {
      color: disabled ? colorWithWhiteness(colors.dark, 0.4) : colors.accent,
      fontSize: '20px',
      marginRight: '0.5rem',
      marginTop: '0.5rem'
    };
  },
  cardText: {
    color: colors.primary,
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
  DATASETS = 'DATA SETS',
  COHORTS = 'COHORTS',
  CONCEPTSETS = 'CONCEPT SETS'
}

const descriptions = {
  data: `The Data Tab is the gateway to all Workbench tools and
  All of Us Research data that will help you complete your research project.
  Here, you can build a  cohorts of participants, select concept sets of
  interest and build analysis-ready tables from the two called datasets.`,
  datasets: `Datasets are analysis-ready tables that can be exported to
  analysis tools such as Notebooks. Users can build and preview a dataset
  for one or more cohorts by selecting the desired concept sets and values
  for the cohorts. `,
  cohorts: `A “Cohort” is a group of participants that researchers are
  interested in. The cohort builder allows you to create and review cohorts
  and annotate participants in a researcher’s study group.`,
  conceptSets: `Concepts describe information in a patient’s medical record,
  such as a condition, a  prescription they are taking or their vital signs.
  Subject areas such as conditions, drugs, measurements etc. are called “domains”.
  Users can search for and save collections of concepts from a particular domain
  as a “Concept set” and then  use concept sets and cohorts to create a dataset,
  which can be used for analysis.`
};

export const DataPage = withCurrentWorkspace()(class extends React.Component<
  {workspace: WorkspaceData},
  {activeTab: Tabs, resourceList: RecentResource[], isLoading: boolean,
    creatingConceptSet: boolean, existingDataSetName: string[],
    existingCohortName: string[], existingConceptSetName: string[]}> {

  constructor(props) {
    super(props);
    this.state = {
      activeTab: Tabs.SHOWALL,
      resourceList: [],
      isLoading: true,
      creatingConceptSet: false,
      existingCohortName: [],
      existingConceptSetName: [],
      existingDataSetName: []
    };
  }

  componentDidMount() {
    this.loadResources();
  }

  async loadResources() {
    try {
      const {namespace, id, accessLevel} = this.props.workspace;

      this.setState({
        isLoading: true
      });
      const [cohorts, conceptSets, dataSets] = await Promise.all([
        cohortsApi().getCohortsInWorkspace(namespace, id),
        conceptSetsApi().getConceptSetsInWorkspace(namespace, id),
        dataSetApi().getDataSetsInWorkspace(namespace, id)
      ]);
      this.setState({
        existingCohortName: cohorts.items.map(cohort => cohort.name),
        existingConceptSetName: conceptSets.items.map(conceptSet => conceptSet.name),
        existingDataSetName: dataSets.items.map(dataSet => dataSet.name)
      });
      let list: RecentResource[] = [];
      list = list.concat(convertToResources(cohorts.items, namespace,
        id, accessLevel as unknown as WorkspaceAccessLevel, ResourceType.COHORT));
      list = list.concat(convertToResources(conceptSets.items, namespace,
        id, accessLevel as unknown as WorkspaceAccessLevel, ResourceType.CONCEPT_SET));
      list = list.concat(convertToResources(dataSets.items, namespace,
        id, accessLevel as unknown as WorkspaceAccessLevel, ResourceType.DATA_SET));
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

  getExistingNameList(resource) {
    if (resource.dataSet) {
      return this.state.existingDataSetName;
    } else if (resource.conceptSet) {
      return this.state.existingConceptSetName;
    } else if (resource.cohort) {
      return this.state.existingCohortName;
    }
    return [];
  }

  render() {
    const {accessLevel, namespace, id} = this.props.workspace;
    const {activeTab, isLoading, resourceList} = this.state;

    const writePermission = accessLevel === WorkspaceAccessLevel.OWNER ||
      accessLevel === WorkspaceAccessLevel.WRITER;

    const filteredList = resourceList.filter((resource) => {
      if (activeTab === Tabs.SHOWALL) {
        return true;
      } else if (activeTab === Tabs.COHORTS) {
        return resource.cohort;
      } else if (activeTab === Tabs.CONCEPTSETS) {
        return resource.conceptSet;
      } else if (activeTab === Tabs.DATASETS) {
        return resource.dataSet;
      }
    });
    return <React.Fragment>
      <FadeBox style={{marginTop: '1rem'}}>
        <h2 style={{marginTop: 0}}>Data</h2>
        <div style={{color: colors.primary, fontSize: '14px'}}>{descriptions.data}</div>
        <div style={styles.cardButtonArea}>
          <TooltipTrigger content={!writePermission &&
          `Write permission required to create cohorts`} side='top'>
            <CardButton style={styles.resourceTypeButton} disabled={!writePermission}
                        onClick={() => {
                          navigate(['workspaces', namespace, id,  'cohorts', 'build']);
                        }}>
              <div style={styles.cardHeader}>
                <h2 style={styles.cardHeaderText(!writePermission)}>Cohorts</h2>
                <ClrIcon shape='plus-circle' class='is-solid' size={18} style={{marginTop: 5}}/>
              </div>
              <div style={styles.cardText}>
                {descriptions.cohorts}
              </div>
            </CardButton>
          </TooltipTrigger>
          <TooltipTrigger content={!writePermission &&
          `Write permission required to create concept sets`} side='top'>
            <CardButton style={styles.resourceTypeButton}
                        disabled={!writePermission}
                        onClick={() => {
                          navigate(['workspaces', namespace, id,  'concepts']);
                        }}>
              <div style={styles.cardHeader}>
                <h2 style={styles.cardHeaderText(!writePermission)}>Concept Sets</h2>
                <ClrIcon shape='plus-circle' class='is-solid' size={18} style={{marginTop: 5}}/>
              </div>
              <div style={styles.cardText}>
                {descriptions.conceptSets}
              </div>
            </CardButton>
          </TooltipTrigger>
          <TooltipTrigger content={!writePermission &&
          `Write permission required to create data sets`} side='top'>
            <CardButton
              style={{...styles.resourceTypeButton, ...styles.resourceTypeButtonLast}}
              disabled={!writePermission}
              onClick={() => {
                navigate(['workspaces', namespace, id, 'data', 'data-sets']);
              }}>
              <div style={styles.cardHeader}>
                <h2 style={styles.cardHeaderText(!writePermission)}>Datasets</h2>
                <ClrIcon shape='plus-circle' class='is-solid' size={18} style={{marginTop: 5}}/>
              </div>
              <div style={styles.cardText}>
                {descriptions.datasets}
              </div>
            </CardButton>
          </TooltipTrigger>
        </div>
      </FadeBox>
      <FadeBox style={{marginTop: '1rem'}}>
        <div style={styles.tabContainer}>
          <h2 style={{margin: 0,
            color: colors.primary,
            fontSize: '16px',
            fontWeight: 600}}>Show:</h2>
          <TabButton active={activeTab === Tabs.SHOWALL} onClick={() => {
            this.setState({
              activeTab: Tabs.SHOWALL
            });
          }}>Show All</TabButton>
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
          <TabButton active={activeTab === Tabs.DATASETS} onClick={() => {
            this.setState({
              activeTab: Tabs.DATASETS
            });
          }} data-test-id='view-only-data-sets'>Datasets</TabButton>
        </div>
        <div style={{
          borderBottom: `1px solid ${colors.dark}`,
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
                                 onDuplicateResource={(duplicating) => this.setState({
                                   isLoading: duplicating
                                 })}
                                 onUpdate={() => this.loadResources()}
                                 existingNameList={this.getExistingNameList(resource)}
            />;
          })}
          {isLoading && <SpinnerOverlay></SpinnerOverlay>}
        </div>
      </FadeBox>
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
