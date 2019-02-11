import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import {ActivatedRoute} from '@angular/router';
import {ClarityModule} from '@clr/angular';
import {NgxChartsModule} from '@swimlane/ngx-charts';
import {ComboChartComponent} from 'app/cohort-common/combo-chart/combo-chart.component';
import {OverviewPage} from 'app/cohort-review/overview-page/overview-page';
import {ParticipantsChartsComponent} from 'app/cohort-review/participants-charts/participant-charts';
import {QueryCohortDefinitionComponent} from 'app/cohort-review/query-cohort-definition/query-cohort-definition.component';
import {QueryDescriptiveStatsComponent} from 'app/cohort-review/query-descriptive-stats/query-descriptive-stats.component';
import {QueryReportComponent} from 'app/cohort-review/query-report/query-report.component';
import {ReviewStateService} from 'app/cohort-review/review-state.service';
import {CdrVersionStorageService} from 'app/services/cdr-version-storage.service';
import {currentCohortStore, currentWorkspaceStore, urlParamsStore} from 'app/utils/navigation';
import {CohortBuilderService, CohortReviewService, DataAccessLevel, WorkspaceAccessLevel} from 'generated';
import {NgxPopperModule} from 'ngx-popper';
import {Observable} from 'rxjs/Observable';
import {CdrVersionStorageServiceStub} from 'testing/stubs/cdr-version-storage-service-stub';
import {CohortBuilderServiceStub} from 'testing/stubs/cohort-builder-service-stub';
import {CohortReviewServiceStub} from 'testing/stubs/cohort-review-service-stub';
import {ReviewStateServiceStub} from 'testing/stubs/review-state-service-stub';
import {WorkspacesServiceStub} from 'testing/stubs/workspace-service-stub';





describe('QueryReportComponent', () => {
  let component: QueryReportComponent;
  let fixture: ComponentFixture<QueryReportComponent>;

  const criteria = {
    includes: [{
      items: [{
        type: 'PM',
        modifiers: [{
          name: 'AGE_AT_EVENT',
          operands: ['60', '30'],
          operator: 'GREATER_THAN_OR_EQUAL_TO'
        }],
        searchParameters: [{
          name: 'Hypotensive (Systolic <= 90 / Diastolic <= 60)',
          type: 'PM'
        }]
      }]
    }],
    excludes: []
  };
  const activatedRouteStub = {
    snapshot: {
      data: {
        review: {}
      }
    }
  };
  let route;

  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [
        ComboChartComponent,
        OverviewPage,
        ParticipantsChartsComponent,
        QueryReportComponent,
        QueryCohortDefinitionComponent,
        QueryDescriptiveStatsComponent
      ],
      imports: [
        ClarityModule,
        NgxChartsModule,
        NgxPopperModule,
      ],
      providers: [
        {provide: ActivatedRoute, useValue: activatedRouteStub},
        { provide: CdrVersionStorageService,
          useValue: new CdrVersionStorageServiceStub({
            defaultCdrVersionId: WorkspacesServiceStub.stubWorkspace().cdrVersionId,
            items: [{
              name: 'cdr1',
              cdrVersionId: WorkspacesServiceStub.stubWorkspace().cdrVersionId,
              dataAccessLevel: DataAccessLevel.Registered,
              creationTime: 0
            }]
          })},
        {provide: CohortBuilderService, useValue: new CohortBuilderServiceStub()},
        {provide: CohortReviewService, useValue: new CohortReviewServiceStub()},
        {provide: ReviewStateService, useValue: new ReviewStateServiceStub()},
      ]
    })
      .compileComponents();
    currentWorkspaceStore.next({
      ...WorkspacesServiceStub.stubWorkspace(),
      cdrVersionId: '1',
      accessLevel: WorkspaceAccessLevel.OWNER,
    });
    currentCohortStore.next({
      name: '',
      criteria: JSON.stringify(criteria),
      type: '',
    });
    urlParamsStore.next({
      ns: 'workspaceNamespace',
      wsid: 'workspaceId',
      cid: 1
    });
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(QueryReportComponent);
    component = fixture.componentInstance;
    route = new ActivatedRoute();
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
