import {DebugElement} from '@angular/core';
import {ComponentFixture, fakeAsync, TestBed, tick} from '@angular/core/testing';
import {FormsModule, ReactiveFormsModule} from '@angular/forms';
import {By} from '@angular/platform-browser';
import {BrowserAnimationsModule} from '@angular/platform-browser/animations';
import {ActivatedRoute, UrlSegment} from '@angular/router';
import {RouterTestingModule} from '@angular/router/testing';

import {ClarityModule} from '@clr/angular';

import {CohortsServiceStub} from 'testing/stubs/cohort-service-stub';
import {SignInServiceStub} from 'testing/stubs/sign-in-service-stub';
import {WorkspacesServiceStub, WorkspaceStubVariables} from 'testing/stubs/workspace-service-stub';
import {
  simulateClick,
  simulateInput,
  updateAndTick
} from 'testing/test-helpers';

import {SignInService} from 'app/services/sign-in.service';
import {CohortListComponent} from 'app/views/cohort-list/component';
import {ConfirmDeleteModalComponent} from 'app/views/confirm-delete-modal/component';
import {EditModalComponent} from 'app/views/edit-modal/component';
import {RenameModalComponent} from 'app/views/rename-modal/component';
import {ResourceCardComponent} from 'app/views/resource-card/component';
import {ToolTipComponent} from 'app/views/tooltip/component';
import {TopBoxComponent} from 'app/views/top-box/component';

import {
  Cohort,
  CohortsService,
  ConceptSetsService,
  RecentResource,
  WorkspaceAccessLevel,
  WorkspacesService
} from 'generated';


const activatedRouteStub  = {
  snapshot: {
    url: [
      {path: 'workspaces'},
      {path: WorkspaceStubVariables.DEFAULT_WORKSPACE_NS},
      {path: WorkspaceStubVariables.DEFAULT_WORKSPACE_ID}
    ],
    params: {
      'ns': WorkspaceStubVariables.DEFAULT_WORKSPACE_NS,
      'wsid': WorkspaceStubVariables.DEFAULT_WORKSPACE_ID
    },
    data: {
      workspace: {
        ...WorkspacesServiceStub.stubWorkspace(),
        accessLevel: WorkspaceAccessLevel.OWNER,
      }
    }
  }
};

class CohortListPage {
  fixture: ComponentFixture<CohortListComponent>;
  route: UrlSegment[];
  form: DebugElement;

  constructor(testBed: typeof TestBed) {
    this.fixture = testBed.createComponent(CohortListComponent);
    this.readPageData();
  }

  readPageData() {
    updateAndTick(this.fixture);
    updateAndTick(this.fixture);
  }
}

describe('CohortListComponent', () => {
  let cohortListPage: CohortListPage;

  beforeEach(fakeAsync(() => {
    TestBed.configureTestingModule({
      imports: [
        BrowserAnimationsModule,
        RouterTestingModule,
        FormsModule,
        ReactiveFormsModule,
        ClarityModule.forRoot()
      ],
      declarations: [
        EditModalComponent,
        CohortListComponent,
        ConfirmDeleteModalComponent,
        RenameModalComponent,
        ResourceCardComponent,
        ToolTipComponent,
        TopBoxComponent
      ],
      providers: [
        { provide: ActivatedRoute, useValue: activatedRouteStub},
        { provide: CohortsService, useValue: new CohortsServiceStub()},
        { provide: ConceptSetsService },
        { provide: SignInService, useValue: new SignInServiceStub()},
        { provide: WorkspacesService, useValue: new WorkspacesServiceStub()}
      ] }).compileComponents().then(() => {
      cohortListPage = new CohortListPage(TestBed);
    });
    tick();
  }));

  it('should delete the correct cohort', fakeAsync(() => {
    const fixture = TestBed.createComponent(CohortListComponent);
    const app = fixture.debugElement.componentInstance;
    updateAndTick(fixture);
    updateAndTick(fixture);
    const firstCohortName = fixture.debugElement.query(By.css('.name')).nativeNode.innerText;
    const deletedResource: RecentResource = app.resourceList.find(
      (r: RecentResource) => r.cohort.name === firstCohortName);
    expect(deletedResource).toBeTruthy();
    simulateClick(fixture, fixture.debugElement.query(By.css('.resource-menu')));
    updateAndTick(fixture);
    updateAndTick(fixture);
    simulateClick(fixture, fixture.debugElement.query(By.css('.trash')));
    updateAndTick(fixture);
    simulateClick(fixture, fixture.debugElement.query(By.css('.confirm-delete-btn')));
    updateAndTick(fixture);
    expect(app).toBeTruthy();
    expect(app.resourceList.length).toBe(1);
    expect(app.resourceList).not.toContain(deletedResource);
  }));

  it('updates the page on edit', fakeAsync(() => {
    const fixture = TestBed.createComponent(CohortListComponent);
    const app = fixture.debugElement.componentInstance;
    const editValue = 'edited name';
    updateAndTick(fixture);
    updateAndTick(fixture);
    const firstCohortName = fixture.debugElement.query(By.css('.name')).nativeNode.innerText;
    simulateClick(fixture, fixture.debugElement.query(By.css('.resource-menu')));
    updateAndTick(fixture);
    updateAndTick(fixture);
    simulateClick(fixture, fixture.debugElement.query(By.css('.pencil')));
    updateAndTick(fixture);
    simulateInput(fixture, fixture.debugElement.query(By.css('.name-input')), editValue);
    updateAndTick(fixture);
    updateAndTick(fixture);
    simulateClick(fixture, fixture.debugElement.query(By.css('.btn-save')));
    updateAndTick(fixture);
    updateAndTick(fixture);
    expect(app).toBeTruthy();
    expect(app.resourceList.length).toBe(2);
    const listOfNames = fixture.debugElement
      .queryAll(By.css('.name')).map(el => el.nativeNode.innerText);
    expect(listOfNames).toContain(editValue);
    expect(listOfNames).not.toContain(firstCohortName);
  }));
});
