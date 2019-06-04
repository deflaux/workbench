import * as fp from 'lodash/fp';
import * as React from 'react';

import {Clickable} from 'app/components/buttons';
import {ResourceCardBase} from 'app/components/card';
import {ResourceCardMenu} from 'app/components/resources';
import {TextModal} from 'app/components/text-modal';
import colors from 'app/styles/colors';
import {reactStyles} from 'app/utils';
import {navigate, navigateByUrl} from 'app/utils/navigation';
import {ResourceType} from 'app/utils/resourceActions';

import {ConfirmDeleteModal} from 'app/views/confirm-delete-modal';
import {ExportDataSetModal} from 'app/views/export-data-set-modal';
import {Domain, RecentResource} from 'generated/fetch';

import {cohortsApi, conceptSetsApi, dataSetApi, workspacesApi} from 'app/services/swagger-fetch-clients';
import {CopyNotebookModal} from 'app/views/copy-notebook-modal';
import {RenameModal} from 'app/views/rename-modal';

const styles = reactStyles({
  card: {
    marginTop: '1rem',
    justifyContent: 'space-between',
    marginRight: '1rem',
    padding: '0.75rem 0.75rem 0rem 0.75rem',
    boxShadow: '0 0 0 0'
  },
  cardName: {
    fontSize: '18px', fontWeight: 500, lineHeight: '22px', color: colors.blue[0],
    cursor: 'pointer', wordBreak: 'break-all', textOverflow: 'ellipsis',
    overflow: 'hidden', display: '-webkit-box', WebkitLineClamp: 3,
    WebkitBoxOrient: 'vertical'
  },
  cardDescription: {
    textOverflow: 'ellipsis', overflow: 'hidden', display: '-webkit-box',
    WebkitLineClamp: 4, WebkitBoxOrient: 'vertical'
  },
  lastModified: {
    color: colors.gray[0],
    fontSize: '11px',
    display: 'inline-block',
    lineHeight: '14px',
    fontWeight: 300,
    marginBottom: '0.2rem'
  },
  resourceType: {
    height: '22px',
    width: 'max-content',
    paddingLeft: '10px',
    paddingRight: '10px',
    borderRadius: '4px 4px 0 0',
    display: 'flex',
    justifyContent: 'center',
    color: colors.white,
    fontFamily: 'Montserrat, sans-serif',
    fontSize: '12px',
    fontWeight: 500
  },
  cardFooter: {
    display: 'flex',
    flexDirection: 'column'
  }
});

const resourceTypeStyles = reactStyles({
  cohort: {
    backgroundColor: colors.yellow[0]
  },
  conceptSet: {
    backgroundColor: colors.purple[2]
  },
  notebook: {
    backgroundColor: colors.green[0]
  },
  dataSet: {
    backgroundColor: colors.blue[2]
  }
});

export interface Props {
  marginTop: string;
  resourceCard: RecentResource;
  onDuplicateResource: Function;
  onUpdate: Function;
  existingNameList?: string[];
}

export interface State {
  confirmDeleting: boolean;
  errorModalBody: string;
  errorModalTitle: string;
  exportingDataSet: boolean;
  invalidResourceError: boolean;
  renaming: boolean;
  showCopyNotebookModal: boolean;
  showErrorModal: boolean;
}

export class ResourceCard extends React.Component<Props, State> {
  public static defaultProps = {
    marginTop: '1rem'
  };

  constructor(props: Props) {
    super(props);
    this.state = {
      confirmDeleting: false,
      errorModalTitle: 'Error Title',
      errorModalBody: 'Error Body',
      exportingDataSet: false,
      invalidResourceError: !(props.resourceCard.notebook ||
        props.resourceCard.cohort ||
        props.resourceCard.conceptSet ||
        props.resourceCard.dataSet),
      renaming: false,
      showCopyNotebookModal: false,
      showErrorModal: false
    };
  }

  // TODO [1/31/19] This method is only necessary until the parent components
  //    (notebook-list, cohort-list, conceptSet-list) have been converted and use the
  //    fetch API models.
  static castConceptSet(resourceCard: RecentResource): RecentResource {
    if (resourceCard.conceptSet) {
      const myTempConceptSet = {...resourceCard.conceptSet,
        domain: resourceCard.conceptSet.domain as Domain};
      return {...resourceCard, conceptSet: myTempConceptSet};
    }
    return resourceCard;
  }

  showErrorModal(title: string, body: string) {
    this.setState({
      showErrorModal: true,
      errorModalTitle: title,
      errorModalBody: body
    });
  }

  get resourceType(): ResourceType {
    if (this.props.resourceCard.notebook) {
      return ResourceType.NOTEBOOK;
    } else if (this.props.resourceCard.cohort) {
      return ResourceType.COHORT;
    } else if (this.props.resourceCard.conceptSet) {
      return ResourceType.CONCEPT_SET;
    } else if (this.props.resourceCard.dataSet) {
      return ResourceType.DATA_SET;
    } else {
      return ResourceType.INVALID;
    }
  }

  get isCohort(): boolean {
    return this.resourceType === ResourceType.COHORT;
  }

  get isConceptSet(): boolean {
    return this.resourceType === ResourceType.CONCEPT_SET;
  }

  get isNotebook(): boolean {
    return this.resourceType === ResourceType.NOTEBOOK;
  }

  get isDataSet(): boolean {
    return this.resourceType === ResourceType.DATA_SET;
  }

  get actionsDisabled(): boolean {
    return !this.writePermission;
  }

  get writePermission(): boolean {
    return this.props.resourceCard.permission === 'OWNER'
      || this.props.resourceCard.permission === 'WRITER';
  }

  get notebookReadOnly(): boolean {
    return this.isNotebook
      && this.props.resourceCard.permission === 'READER';
  }

  get displayName(): string {
    if (this.isNotebook) {
      return this.props.resourceCard.notebook.name.replace(/\.ipynb$/, '');
    } else if (this.isCohort) {
      return this.props.resourceCard.cohort.name;
    } else if (this.isConceptSet) {
      return this.props.resourceCard.conceptSet.name;
    } else if (this.isDataSet) {
      return this.props.resourceCard.dataSet.name;
    }
  }

  get displayDate(): string {
    const date = new Date(Number(this.props.resourceCard.modifiedTime));
    // datetime formatting to slice off weekday from readable date string
    return date.toDateString().split(' ').slice(1).join(' ');
  }

  get description(): string {
    if (this.isCohort) {
      return this.props.resourceCard.cohort.description;
    } else if (this.isConceptSet) {
      return this.props.resourceCard.conceptSet.description;
    } else if (this.isDataSet) {
      return this.props.resourceCard.dataSet.description;
    }
  }

  edit(): void {
    switch (this.resourceType) {
      case ResourceType.COHORT: {
        const url =
          '/workspaces/' + this.props.resourceCard.workspaceNamespace + '/' +
          this.props.resourceCard.workspaceFirecloudName + '/cohorts/build?cohortId=';
        navigateByUrl(url + this.props.resourceCard.cohort.id);
        this.props.onUpdate();
        break;
      }
      case ResourceType.DATA_SET: {
        navigate(['workspaces',
          this.props.resourceCard.workspaceNamespace,
          this.props.resourceCard.workspaceFirecloudName,
          'data', 'data-sets', this.props.resourceCard.dataSet.id]);
        break;
      }
      default: {
        this.setState({renaming: true});
      }
    }
  }

  reviewCohort(): void {
    const {resourceCard: {workspaceNamespace, workspaceFirecloudName, cohort: {id}}} = this.props;
    navigateByUrl(
      `/workspaces/${workspaceNamespace}/${workspaceFirecloudName}/cohorts/${id}/review`);
  }

  renameCohort(): void {
    this.setState({renaming: true});
  }

  renameNotebook(): void {
    this.setState({renaming: true});
  }

  cancelRename(): void {
    this.setState({renaming: false});
  }

  cancelRenameDataSet(): void {
    this.setState({renaming: false});
  }

  openConfirmDelete(): void {
    this.setState({confirmDeleting: true});
  }

  closeConfirmDelete(): void {
    this.setState({confirmDeleting: false});
  }

  cloneResource(): void {
    this.props.onDuplicateResource(true);
    switch (this.resourceType) {
      case ResourceType.NOTEBOOK: {
        workspacesApi().cloneNotebook(
          this.props.resourceCard.workspaceNamespace,
          this.props.resourceCard.workspaceFirecloudName,
          this.props.resourceCard.notebook.name)
          .then(() => {
            this.props.onUpdate();
          }).catch(e => {
            this.props.onDuplicateResource(false);
            this.showErrorModal('Duplicating Notebook Error',
              'Notebook with the same name already exists.');
          });
        break;
      }
      case ResourceType.COHORT: {
        cohortsApi().duplicateCohort(
          this.props.resourceCard.workspaceNamespace,
          this.props.resourceCard.workspaceFirecloudName,
          {
            originalCohortId: this.props.resourceCard.cohort.id,
            newName: `Duplicate of ${this.props.resourceCard.cohort.name}`
          }
        ).then(() => {
          this.props.onUpdate();
        }).catch(e => {
          this.props.onDuplicateResource(false);
          this.showErrorModal('Duplicating Cohort Error',
            'Cohort with the same name already exists.');
        });
        break;
      }
    }
  }

  copyResource(): void {
    switch (this.resourceType) {
      case ResourceType.NOTEBOOK: {
        this.setState({ showCopyNotebookModal: true });
        break;
      }
    }
  }

  receiveDelete(): void {
    switch (this.resourceType) {
      case ResourceType.NOTEBOOK: {
        workspacesApi().deleteNotebook(
          this.props.resourceCard.workspaceNamespace,
          this.props.resourceCard.workspaceFirecloudName,
          this.props.resourceCard.notebook.name)
          .then(() => {
            this.closeConfirmDelete();
            this.props.onUpdate();
          });
        break;
      }
      case ResourceType.COHORT: {
        cohortsApi().deleteCohort(
          this.props.resourceCard.workspaceNamespace,
          this.props.resourceCard.workspaceFirecloudName,
          this.props.resourceCard.cohort.id)
          .then(() => {
            this.closeConfirmDelete();
            this.props.onUpdate();
          });
        break;
      }
      case ResourceType.CONCEPT_SET: {
        conceptSetsApi().deleteConceptSet(
          this.props.resourceCard.workspaceNamespace,
          this.props.resourceCard.workspaceFirecloudName,
          this.props.resourceCard.conceptSet.id)
          .then(() => {
            this.closeConfirmDelete();
            this.props.onUpdate();
          });
        break;
      }
      case ResourceType.DATA_SET: {
        dataSetApi().deleteDataSet(
          this.props.resourceCard.workspaceNamespace,
          this.props.resourceCard.workspaceFirecloudName,
          this.props.resourceCard.dataSet.id)
          .then(() => {
            this.closeConfirmDelete();
            this.props.onUpdate();
          });
        break;
      }
    }
  }

  fullNotebookName(name) {
    return !name || /^.+\.ipynb$/.test(name) ? name : `${name}.ipynb`;
  }

  receiveRename(name, description): void {
    if (this.isCohort) {
      const request = {
        ...this.props.resourceCard.cohort,
        name: name,
        description: description
      };
      cohortsApi().updateCohort(
        this.props.resourceCard.workspaceNamespace,
        this.props.resourceCard.workspaceFirecloudName,
        this.props.resourceCard.cohort.id,
        request
      ).then(() => {
        this.cancelRename();
        this.props.onUpdate();
      });
    } else if (this.isConceptSet) {
      const request = {
        ...this.props.resourceCard.conceptSet,
        name: name,
        description: description
      };
      conceptSetsApi().updateConceptSet(
        this.props.resourceCard.workspaceNamespace,
        this.props.resourceCard.workspaceFirecloudName,
        this.props.resourceCard.conceptSet.id,
        request
      ).then(() => {
        this.cancelRename();
        this.props.onUpdate();
      });
    }

  }

  async receiveDataSetRename(newName: string, newDescription: string) {
    const {resourceCard} = this.props;
    try {
      const request = {
        ...resourceCard.dataSet,
        name: newName,
        description: newDescription,
        conceptSetIds: resourceCard.dataSet.conceptSets.map(concept => concept.id),
        cohortIds: resourceCard.dataSet.cohorts.map(cohort => cohort.id),
      };
      await dataSetApi().updateDataSet(
        resourceCard.workspaceNamespace,
        resourceCard.workspaceFirecloudName,
        resourceCard.dataSet.id,
        request);
    } catch (error) {
      console.error(error); // TODO: better error handling
    } finally {
      this.setState({renaming: false});
      this.props.onUpdate();
    }
  }

  async receiveNotebookRename(newName) {
    const {resourceCard} = this.props;
    try {
      await workspacesApi().renameNotebook(
        resourceCard.workspaceNamespace,
        resourceCard.workspaceFirecloudName,
        {
          name: resourceCard.notebook.name,
          newName: this.fullNotebookName(newName)
        });
    } catch (error) {
      console.error(error); // TODO: better error handling
    } finally {
      this.setState({renaming: false});
      this.props.onUpdate();
    }
  }

  openResource(jupyterLab?: boolean): void {
    switch (this.resourceType) {
      case ResourceType.COHORT: {
        this.reviewCohort();
        break;
      }
      case ResourceType.CONCEPT_SET: {
        navigate(['workspaces', this.props.resourceCard.workspaceNamespace,
          this.props.resourceCard.workspaceFirecloudName, 'concepts', 'sets',
          this.props.resourceCard.conceptSet.id], {relativeTo: null});
        break;
      }
      case ResourceType.NOTEBOOK: {
        const queryParams = {
          playgroundMode: false,
          jupyterLabMode: jupyterLab
        };
        if (this.notebookReadOnly) {
          queryParams.playgroundMode = true;
        }
        navigate(
          ['workspaces', this.props.resourceCard.workspaceNamespace,
            this.props.resourceCard.workspaceFirecloudName, 'notebooks',
            encodeURIComponent(this.props.resourceCard.notebook.name)], {
              queryParams,
              relativeTo: null,
            });
        break;
      }
      case ResourceType.DATA_SET: {
        navigate(['/workspaces', this.props.resourceCard.workspaceNamespace,
          this.props.resourceCard.workspaceFirecloudName, 'data', 'data-sets',
          this.props.resourceCard.dataSet.id]);
        break;
      }
    }
  }

  exportDataSet(): void {
    this.setState({exportingDataSet: true});
  }

  renameDataSet(): void {
    this.setState({renaming: true});
  }
  render() {
    const marginTop = this.props.marginTop;
    return <React.Fragment>
      {this.state.invalidResourceError &&
        <TextModal
          title='Invalid Resource Type'
          body='Please Report a Bug.'
          onConfirm={() => this.setState({invalidResourceError: false})}/>
      }
      {this.state.showErrorModal &&
        <TextModal
          title={this.state.errorModalTitle}
          body={this.state.errorModalBody}
          onConfirm={() => this.setState({showErrorModal: false})}/>
      }
      {this.state.showCopyNotebookModal &&
        <CopyNotebookModal
          fromWorkspaceNamespace={this.props.resourceCard.workspaceNamespace}
          fromWorkspaceName={this.props.resourceCard.workspaceFirecloudName}
          fromNotebook={this.props.resourceCard.notebook}
          onClose={() => this.setState({ showCopyNotebookModal: false })}
          onCopy={() => this.props.onUpdate() }/>
      }
      <ResourceCardBase style={{...styles.card, marginTop: marginTop}}
                        data-test-id='card'>
        <div style={{display: 'flex', flexDirection: 'column', alignItems: 'flex-start'}}>
          <div style={{display: 'flex', flexDirection: 'row', alignItems: 'flex-start'}}>
            <ResourceCardMenu disabled={this.actionsDisabled}
                              resourceType={this.resourceType}
                              onCloneResource={() => this.cloneResource()}
                              onCopyResource={() => this.copyResource()}
                              onDeleteResource={() => this.openConfirmDelete()}
                              onRenameNotebook={() => this.renameNotebook()}
                              onRenameCohort={() => this.renameCohort()}
                              onRenameDataSet={() => this.renameDataSet()}
                              onEdit={() => this.edit()}
                              onExportDataSet={() => this.exportDataSet()}
                              onReviewCohort={() => this.reviewCohort()}
                              onOpenJupyterLabNotebook={() => this.openResource(true)}/>
            <Clickable disabled={this.actionsDisabled && !this.notebookReadOnly}>
              <div style={styles.cardName}
                   data-test-id='card-name'
                   onClick={() => this.openResource()}>{this.displayName}
              </div>
            </Clickable>
          </div>
          <div style={styles.cardDescription}>{this.description}</div>
        </div>
        <div style={styles.cardFooter}>
          <div style={styles.lastModified}>
            Last Modified: {this.displayDate}</div>
          <div style={{...styles.resourceType, ...resourceTypeStyles[this.resourceType]}}
               data-test-id='card-type'>
            {fp.startCase(fp.camelCase(this.resourceType.toString()))}</div>
        </div>
      </ResourceCardBase>
      {this.state.renaming && this.isCohort &&
        <RenameModal
          onRename={(newName, newDescription) => this.receiveRename(newName, newDescription)}
          type='Cohort'
          onCancel={() => this.cancelRename()}
          oldDescription={this.props.resourceCard.cohort.description}
          oldName={this.props.resourceCard.cohort.name}
          existingNames={this.props.existingNameList}/>
      }
      {this.state.renaming && this.isConceptSet &&
        <RenameModal
          onRename={(newName, newDescription) => this.receiveRename(newName, newDescription)}
          type='Concept Set'
          onCancel={() => this.cancelRename()}
          oldDescription={this.props.resourceCard.conceptSet.description}
          oldName={this.props.resourceCard.conceptSet.name}
          existingNames={this.props.existingNameList}/>}
      {this.state.renaming && this.isNotebook &&
       <RenameModal onRename={(newName) => this.receiveNotebookRename(newName)}
          type='Notebook' onCancel={() => this.cancelRename()}
          hideDescription={true}
          oldName={this.props.resourceCard.notebook.name}
          existingNames={this.props.existingNameList}
          nameFormat={(name) => this.fullNotebookName(name)}/>
      }
      {this.state.confirmDeleting &&
      <ConfirmDeleteModal resourceName={this.displayName}
                          resourceType={this.resourceType}
                          receiveDelete={() => this.receiveDelete()}
                          closeFunction={() => this.closeConfirmDelete()}/>}
      {this.state.exportingDataSet &&
      <ExportDataSetModal dataSet={this.props.resourceCard.dataSet}
                          workspaceNamespace={this.props.resourceCard.workspaceNamespace}
                          workspaceFirecloudName={this.props.resourceCard.workspaceFirecloudName}
                          closeFunction={() => this.setState({exportingDataSet: false})}/>}
      {this.state.renaming && this.isDataSet &&
        <RenameModal
          onRename={(newName, newDescription) => this.receiveDataSetRename(newName, newDescription)}
          type='Data Set'
          onCancel={() => this.cancelRename()}
          oldDescription ={this.props.resourceCard.dataSet.description}
          oldName={this.props.resourceCard.dataSet.name}
          existingNames={this.props.existingNameList}/>
      }
    </React.Fragment>;
  }
}