import {Component, Input} from '@angular/core';
import * as fp from 'lodash/fp';
import * as React from 'react';
import {withContentRect} from 'react-measure';

import {SpinnerOverlay} from 'app/components/spinners';
import {Scroll} from 'app/icons/scroll';
import {cohortsApi, conceptSetsApi, userMetricsApi, workspacesApi} from 'app/services/swagger-fetch-clients';

import {ReactWrapperBase, withCurrentWorkspace} from 'app/utils';
import {convertToResources, ResourceType} from 'app/utils/resourceActionsReact';
import {WorkspaceData} from 'app/utils/workspace-data';
import {ResourceCard} from 'app/views/resource-card';
import {RecentResource, WorkspaceAccessLevel} from 'generated/fetch';

export const RecentWork = (fp.flow as any)(
  withContentRect('client'),
  withCurrentWorkspace()
)(class extends React.Component<{
  workspace: WorkspaceData,
  measureRef: React.Ref<any>,
  contentRect: {client: {width: number}},
  dark: boolean,
  cardMarginTop: string
}, {
  loading: boolean,
  offset: number,
  resources: RecentResource[],
  existingCohortName: string[],
  existingConceptName: string[],
  existingNotebookName: string[]
}> {
  public static defaultProps = {
    cardMarginTop: '1rem'
  };

  constructor(props) {
    super(props);
    this.state = {
      loading: false,
      resources: [],
      offset: 0,
      existingCohortName: [],
      existingConceptName: [],
      existingNotebookName: []};
  }

  componentDidMount() {
    this.loadResources();
  }

  async loadResources() {
    try {
      const {workspace} = this.props;
      this.setState({loading: true});
      const resources = await (async() => {
        if (workspace) {
          const {namespace, id, accessLevel} = workspace;
          const [notebooks, cohorts, conceptSets] = await Promise.all([
            workspacesApi().getNoteBookList(namespace, id),
            cohortsApi().getCohortsInWorkspace(namespace, id),
            conceptSetsApi().getConceptSetsInWorkspace(namespace, id)
          ]);
          this.setState({
            existingCohortName: cohorts.items.map(cohort => cohort.name),
            existingConceptName: conceptSets.items.map(conceptSet => conceptSet.name),
            existingNotebookName: notebooks.map(notebook => notebook.name)
          });
          // TODO Remove this cast when we switch to fetch types
          const al = accessLevel as unknown as WorkspaceAccessLevel;
          const convert = (col, type) => convertToResources(col, namespace, id, al, type);
          return fp.reverse(fp.sortBy('modifiedTime', [
            ...convert(notebooks, ResourceType.NOTEBOOK),
            ...convert(cohorts.items, ResourceType.COHORT),
            ...convert(conceptSets.items, ResourceType.CONCEPT_SET)
          ]));
        } else {
          return userMetricsApi().getUserRecentResources();
        }
      })();
      this.setState({resources});
    } catch (error) {
      console.error(error);
    } finally {
      this.setState({loading: false});
    }
  }

  getExistingNameList(resource) {
    if (resource.notebook) {
      return this.state.existingNotebookName;
    } else if (resource.conceptSet) {
      return this.state.existingConceptName;
    } else if (resource.cohort) {
      return this.state.existingCohortName;
    }
    return [];
  }

  render() {
    const {contentRect, measureRef, workspace, cardMarginTop} = this.props;
    const {offset, resources, loading} = this.state;
    const limit = (contentRect.client.width - 24) / 224;
    const shade = workspace ? 'light' : 'dark';
    return <div ref={measureRef} style={{display: 'flex', position: 'relative', minHeight: 247}}>
      <div style={{display: 'flex', position: 'relative',
        paddingLeft: '1rem', opacity: loading ? 0.5 : 1}}>
        {resources.slice(offset, offset + limit).map((resource, i) => {
          return <ResourceCard key={i} marginTop={cardMarginTop}
            onDuplicateResource={(duplicating) => this.setState({loading: duplicating})}
            resourceCard={resource} onUpdate={() => this.loadResources()}
            existingNameList={this.getExistingNameList(resource)}
          />;
        })}
        {offset > 0 && <Scroll
          dir='left' shade={shade}
          onClick={() => this.setState({offset: offset - 1})}
          style={{position: 'absolute', top: 110, left: 0}}
        />}
        {offset + limit < resources.length && <Scroll
          dir='right' shade={shade}
          onClick={() => this.setState({offset: offset + 1})}
          style={{position: 'absolute', top: 110, right: 0}}
        />}
      </div>
      {loading && <SpinnerOverlay dark={this.props.dark} />}
    </div>;
  }
});

@Component({
  selector: 'app-recent-work',
  template: '<div #root></div>',
})
export class RecentWorkComponent extends ReactWrapperBase {
  @Input('dark') dark: boolean;
  @Input('cardMarginTop') cardMarginTop: string;
  constructor() {
    super(RecentWork, ['dark', 'cardMarginTop']);
  }
}