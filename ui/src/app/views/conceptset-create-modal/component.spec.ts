import {DebugElement} from '@angular/core';
import {ComponentFixture, fakeAsync, TestBed, tick} from '@angular/core/testing';
import {FormsModule} from '@angular/forms';
import {By} from '@angular/platform-browser';
import {BrowserAnimationsModule} from '@angular/platform-browser/animations';
import {ActivatedRoute, UrlSegment} from '@angular/router';
import {RouterTestingModule} from '@angular/router/testing';
import {ClarityModule} from '@clr/angular';
import {ConceptsService, WorkspaceResponse, WorkspacesService} from '../../../generated';
import {ConceptSetsService} from '../../../generated/api/conceptSets.service';
import {ConceptsServiceStub} from '../../../testing/stubs/concept-service-stub';
import {ConceptSetsServiceStub} from '../../../testing/stubs/concept-sets-service-stub';
import {ProfileStorageServiceStub} from '../../../testing/stubs/profile-storage-service-stub';
import {ServerConfigServiceStub} from '../../../testing/stubs/server-config-service-stub';
import {
  WorkspacesServiceStub,
  WorkspaceStubVariables
} from '../../../testing/stubs/workspace-service-stub';
import {simulateClick, simulateInput, updateAndTick} from '../../../testing/test-helpers';
import {ServerConfigService} from '../../services/server-config.service';
import {WorkspaceShareComponent} from '../workspace-share/component';
import {CreateConceptSetModalComponent} from './component';

class ConceptSetCreatePage {
  fixture: ComponentFixture<CreateConceptSetModalComponent>;
  route: UrlSegment[];
  conceptSetService: ConceptSetsService;
  workspacesService: WorkspacesService;
  workspaceNamespace: string;
  workspaceId: string;
  conceptList: any[] = [];
  name: DebugElement;
  description: DebugElement;
  conceptSelect: DebugElement;
  save: DebugElement;


  constructor(testBed: typeof TestBed) {
    this.fixture = testBed.createComponent(CreateConceptSetModalComponent);
    this.route = this.fixture.debugElement.injector.get(ActivatedRoute).snapshot.url;
    this.workspacesService = this.fixture.debugElement.injector.get(WorkspacesService);

    this.conceptSetService = this.fixture.debugElement.injector.get(ConceptSetsService);

    this.workspacesService.getWorkspace(
        WorkspaceStubVariables.DEFAULT_WORKSPACE_NS,
        WorkspaceStubVariables.DEFAULT_WORKSPACE_ID).subscribe((response: WorkspaceResponse) => {
      this.fixture.componentInstance.wsId = response.workspace.id;
      this.fixture.componentInstance.wsNamespace = response.workspace.namespace;
    });
    tick();
    this.readPageData();
  }

  readPageData() {
    updateAndTick(this.fixture);
    updateAndTick(this.fixture);
    this.workspaceNamespace = this.route[1].path;
    this.workspaceId = this.route[2].path;
    const de = this.fixture.debugElement;
    const conceptList = de.queryAll(By.css('.concept-select'));
    this.name = de.query(By.css('.input-name'));
    this.description = de.query(By.css('.input-description'));
    this.save = de.query(By.css('.btn-primary'));
    this.conceptSelect = conceptList[0];

    if ( conceptList && conceptList.length > 0) {
    conceptList[0].childNodes.forEach((concepts) => {
      console.log(concepts.nativeNode);
    });
    }
  }
}
  const activatedRouteStub  = {
    snapshot: {
      url: [
        {path: 'workspaces'},
        {path: WorkspaceStubVariables.DEFAULT_WORKSPACE_NS},
        {path: WorkspaceStubVariables.DEFAULT_WORKSPACE_ID},
      ],
      params: {
        'ns': WorkspaceStubVariables.DEFAULT_WORKSPACE_NS,
        'wsid': WorkspaceStubVariables.DEFAULT_WORKSPACE_ID
      }
    }
  };

describe('ConceptSetComponent', () => {
  let conceptSetCreatePage: ConceptSetCreatePage;
  const concetServiceStub = new ConceptsServiceStub();
  const concetSetServiceStub = new ConceptSetsServiceStub();
  beforeEach(fakeAsync(() => {
    TestBed.configureTestingModule({
      imports: [
        BrowserAnimationsModule,
        RouterTestingModule,
        FormsModule,
        ClarityModule.forRoot()
      ],
      declarations: [
        CreateConceptSetModalComponent
      ],
      providers: [
        {provide: ConceptSetsService, useValue: concetSetServiceStub},
        {provide: ActivatedRoute, useValue: activatedRouteStub},
        {provide: ConceptsService, useValue: concetServiceStub},
        {provide: WorkspacesService, useValue: new WorkspacesServiceStub() }
      ]
    }).compileComponents().then(() => {
      conceptSetCreatePage = new ConceptSetCreatePage(TestBed);
    });
    tick();
  }));

  /*it('gets domains on open', fakeAsync( () => {
    const spyObj = spyOn(concetServiceStub, 'getDomainInfo');
    conceptSetCreatePage.fixture.componentRef.instance.open();
    conceptSetCreatePage.readPageData();
    tick();
    expect(spyObj).toHaveBeenCalledWith(this.workspaceNamespace, this.workspaceId);
  }));*/

  it('saves concept sets information', fakeAsync(() => {
    const spyObj = spyOn(concetSetServiceStub, 'createConceptSet');

    conceptSetCreatePage.fixture.componentRef.instance.open();
    conceptSetCreatePage.readPageData();
    simulateInput(conceptSetCreatePage.fixture, conceptSetCreatePage.name, 'Concept');
    simulateInput(conceptSetCreatePage.fixture, conceptSetCreatePage.description, 'Description');
    simulateClick(conceptSetCreatePage.fixture , conceptSetCreatePage.save);
    expect(spyObj).toHaveBeenCalled();
  }));
});

