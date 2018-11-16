import {ComponentFixture, fakeAsync, TestBed, tick} from '@angular/core/testing';
import {By} from '@angular/platform-browser';
import {RouterTestingModule} from '@angular/router/testing';

import {FormsModule, ReactiveFormsModule} from '@angular/forms';

import {ClarityModule} from '@clr/angular';

import {ProfileService} from 'generated';

import {ConceptSetsServiceStub} from 'testing/stubs/concept-sets-service-stub';
import {ProfileServiceStub, ProfileStubVariables} from 'testing/stubs/profile-service-stub';
import {ProfileStorageServiceStub} from 'testing/stubs/profile-storage-service-stub';
import {ServerConfigServiceStub} from 'testing/stubs/server-config-service-stub';
import {UserMetricsServiceStub} from 'testing/stubs/user-metrics-service-stub';

import {simulateClick, updateAndTick} from 'testing/test-helpers';

import {ProfileStorageService} from 'app/services/profile-storage.service';
import {ServerConfigService} from 'app/services/server-config.service';
import {CohortsService} from 'generated/api/cohorts.service';
import {ConceptSetsService} from 'generated/api/conceptSets.service';
import {UserMetricsService} from 'generated/api/userMetrics.service';
import {WorkspacesService} from 'generated/api/workspaces.service';

import {ConfirmDeleteModalComponent} from 'app/views/confirm-delete-modal/component';
import {EditModalComponent} from 'app/views/edit-modal/component';
import {HomepageComponent} from 'app/views/homepage/component';
import {QuickTourModalComponent} from 'app/views/quick-tour-modal/component';
import {RecentWorkComponent} from 'app/views/recent-work/component';
import {RenameModalComponent} from 'app/views/rename-modal/component';
import {ResourceCardComponent} from 'app/views/resource-card/component';

import {ExpandComponent} from 'app/icons/expand/component';
import {LeftScrollLightComponent} from 'app/icons/left-scroll-light/component';
import {LeftScrollComponent} from 'app/icons/left-scroll/component';
import {RightScrollLightComponent} from 'app/icons/right-scroll-light/component';
import {RightScrollComponent} from 'app/icons/right-scroll/component';
import {ShrinkComponent} from 'app/icons/shrink/component';

describe('HomepageComponent', () => {
  let fixture: ComponentFixture<HomepageComponent>;
  let profileStub: ProfileServiceStub;
  beforeEach(fakeAsync(() => {
    profileStub = new ProfileServiceStub();
    TestBed.configureTestingModule({
      imports: [
        RouterTestingModule,
        FormsModule,
        ReactiveFormsModule,
        ClarityModule.forRoot()
      ],
      declarations: [
        HomepageComponent,
        RecentWorkComponent,
        LeftScrollComponent,
        QuickTourModalComponent,
        LeftScrollLightComponent,
        RightScrollComponent,
        RightScrollLightComponent,
        ResourceCardComponent,
        ConfirmDeleteModalComponent,
        RenameModalComponent,
        EditModalComponent,
        ExpandComponent,
        ShrinkComponent
      ],
      providers: [
        {provide: CohortsService},
        {provide: ConceptSetsService, useVale: new ConceptSetsServiceStub() },
        {provide: ProfileService, useValue: profileStub},
        {provide: ProfileStorageService, useValue: new ProfileStorageServiceStub()},
        {provide: WorkspacesService },
        {provide: UserMetricsService, useValue: new UserMetricsServiceStub()},
        {
          provide: ServerConfigService,
          useValue: new ServerConfigServiceStub({
            gsuiteDomain: 'fake-research-aou.org'
          })
        },
      ]
    }).compileComponents().then(() => {
      fixture = TestBed.createComponent(HomepageComponent);
    });
  }));

  const loadProfileWithPageVisits = (p: any) => {
    profileStub.profile = {
      ...ProfileStubVariables.PROFILE_STUB,
      pageVisits: p.pageVisits
    };
  };

  it('should render', fakeAsync(() => {
    loadProfileWithPageVisits({pageVisits: [{page: 'homepage'}]});
    updateAndTick(fixture);
    expect(fixture).toBeTruthy();
  }));

  it('should display quick tour when clicked', fakeAsync(() =>  {
    loadProfileWithPageVisits({pageVisits: [{page: 'homepage'}]});
    updateAndTick(fixture);
    simulateClick(fixture, fixture.debugElement.query(By.css('#learn')));
    tick(1000);
    expect(fixture.debugElement.query(By.css('#quick-tour'))).toBeTruthy();
  }));

  it('should display quick tour on first visit', fakeAsync(() => {
    updateAndTick(fixture);
    tick(1000);
    updateAndTick(fixture);
    expect(fixture.debugElement.queryAll(By.css('#quick-tour')).length).toBe(1);
  }));

  it('should not auto display quick tour if not first visit', fakeAsync(() => {
    loadProfileWithPageVisits({pageVisits: [{page: 'homepage'}]});
    updateAndTick(fixture);
    tick(1000);
    expect(fixture.debugElement.queryAll(By.css('#quick-tour')).length).toBe(0);
  }));

  it('should close quick tour when closed', fakeAsync(() => {
    updateAndTick(fixture);
    tick(1000);
    updateAndTick(fixture);
    simulateClick(fixture, fixture.debugElement.query(By.css('#close')));
    updateAndTick(fixture);
    expect(fixture.debugElement.query(By.css('#quick-tour'))).toBeNull();
  }));
});
