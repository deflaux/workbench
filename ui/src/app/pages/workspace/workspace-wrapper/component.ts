import {Component, OnDestroy, OnInit, ViewChild} from '@angular/core';
import {ActivatedRoute, NavigationEnd, Router} from '@angular/router';
import * as fp from 'lodash/fp';

import {WorkspaceShareComponent} from 'app/pages/workspace/workspace-share';
import {workspacesApi} from 'app/services/swagger-fetch-clients';
import {
  currentWorkspaceStore, navigate, routeConfigDataStore, urlParamsStore,
  userProfileStore
} from 'app/utils/navigation';

import {
  UserRole,
  Workspace,
  WorkspaceAccessLevel,
} from 'generated/fetch';

@Component({
  styleUrls: ['../../../styles/buttons.css',
    '../../../styles/headers.css'],
  templateUrl: './component.html',
})
export class WorkspaceWrapperComponent implements OnInit, OnDestroy {
  @ViewChild(WorkspaceShareComponent)
  shareModal: WorkspaceShareComponent;

  workspace: Workspace;
  accessLevel: WorkspaceAccessLevel;
  deleting = false;
  sharing = false;
  workspaceDeletionError = false;
  tabPath: string;
  displayNavBar = true;
  confirmDeleting = false;
  username: string;
  menuDataLoading = false;
  userRoles?: UserRole[];

  bugReportOpen: boolean;
  bugReportDescription = '';

  private subscriptions = [];

  constructor(
    private route: ActivatedRoute,
    private router: Router,
  ) {
    this.handleShareAction = this.handleShareAction.bind(this);
    this.closeShare = this.closeShare.bind(this);
    this.openConfirmDelete = this.openConfirmDelete.bind(this);
    this.receiveDelete = this.receiveDelete.bind(this);
    this.closeConfirmDelete = this.closeConfirmDelete.bind(this);
    this.closeBugReport = this.closeBugReport.bind(this);
  }

  ngOnInit(): void {
    this.tabPath = this.getTabPath();
    this.subscriptions.push(
      this.router.events.filter(event => event instanceof NavigationEnd)
        .subscribe(event => {
          this.tabPath = this.getTabPath();
        }));
    this.subscriptions.push(routeConfigDataStore.subscribe(({minimizeChrome}) => {
      this.displayNavBar = !minimizeChrome;
    }));
    this.subscriptions.push(urlParamsStore
      .map(({ns, wsid}) => ({ns, wsid}))
      .distinctUntilChanged(fp.isEqual)
      .switchMap(({ns, wsid}) => {
        // Clear the workspace/access level during the transition to ensure we
        // do not render the child component with a stale workspace.
        this.workspace = undefined;
        this.accessLevel = undefined;
        // This needs to happen for testing because we seed the urlParamsStore with {}.
        // Otherwise it tries to make an api call with undefined, because the component
        // initializes before we have access to the route.
        if (ns === undefined || wsid === undefined) {
          return Promise.resolve(null);
        }
        return workspacesApi().getWorkspace(ns, wsid).then((wsResponse) => {
          return {
            ...wsResponse.workspace,
            accessLevel: wsResponse.accessLevel
          };
        });
      })
      .subscribe(workspace => {
        if (workspace === null) {
          // This handles the empty urlParamsStore story.
          return;
        }
        this.workspace = workspace;
        this.accessLevel = workspace.accessLevel;
        currentWorkspaceStore.next(workspace);
      })
    );
    this.subscriptions.push(currentWorkspaceStore.subscribe((workspace) => {
      if (workspace) {
        this.workspace = workspace;
        this.accessLevel = workspace.accessLevel;
      }
    }));
    this.subscriptions.push(userProfileStore.subscribe((profileResp) => {
      this.username = profileResp.profile.username;
    }));
  }

  ngOnDestroy() {
    currentWorkspaceStore.next(undefined);
    for (const s of this.subscriptions) {
      s.unsubscribe();
    }
  }

  private getTabPath(): string {
    const child = this.route.firstChild;
    if (!child) {
      return '';
    }
    const path = child.routeConfig.path;
    if (!path.includes('/')) {
      return path;
    }
    return path.slice(0, path.indexOf('/'));
  }

  delete(workspace: Workspace): void {
    this.deleting = true;
    workspacesApi().deleteWorkspace(
      workspace.namespace, workspace.id).then(() => {
        navigate(['/workspaces']);
      }).catch(() => {
        this.workspaceDeletionError = true;
      });
  }

  receiveDelete(): void {
    this.delete(this.workspace);
  }

  openConfirmDelete(): void {
    this.confirmDeleting = true;
  }

  closeConfirmDelete(): void {
    this.confirmDeleting = false;
  }

  // The function called when the "share" action is called from the workspace nav bar menu dropdown
  async handleShareAction() {
    this.menuDataLoading = true;

    const userRolesResponse = await workspacesApi().getFirecloudWorkspaceUserRoles(
      this.workspace.namespace,
      this.workspace.id);
    // Trigger the sharing dialog to be shown.
    this.menuDataLoading = false;
    this.userRoles = userRolesResponse.items;
    this.sharing = true;
  }

  closeShare(): void {
    this.sharing = false;
  }

  submitWorkspaceDeleteBugReport(): void {
    this.workspaceDeletionError = false;
    // this.bugReportComponent.reportBug();
    this.bugReportDescription = 'Could not delete workspace.';
    this.bugReportOpen = true;
  }

  closeBugReport(): void {
    this.bugReportOpen = false;
  }
}
