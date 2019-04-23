import {NgRedux} from '@angular-redux/store';
import {MockNgRedux} from '@angular-redux/store/testing';
import {async, ComponentFixture, TestBed} from '@angular/core/testing';
import {ReactiveFormsModule} from '@angular/forms';
import {By} from '@angular/platform-browser';
import {ClarityModule} from '@clr/angular';
import {ValidatorErrorsComponent} from 'app/cohort-common/validator-errors/validator-errors.component';
import {ListSearchGroupItemComponent} from 'app/cohort-search/list-search-group-item/list-search-group-item.component';
import {fromJS} from 'immutable';
import {NgxPopperModule} from 'ngx-popper';

import {CohortSearchActions} from 'app/cohort-search/redux';
import {ListSearchGroupComponent} from './list-search-group.component';

import {CohortBuilderService, DomainType} from 'generated';

const group = {
  id: 'include0',
  count: null,
  isRequesting: false,
  items: [
    {
      id: 'itemA',
      type: DomainType.MEASUREMENT,
      searchParameters: [],
      modifiers: [],
      count: null,
      temporalGroup: 0,
      isRequesting: false,
      status: 'active'
    },
    {
      id: 'itemB',
      type: DomainType.MEASUREMENT,
      searchParameters: [],
      modifiers: [],
      count: null,
      temporalGroup: 0,
      isRequesting: false,
      status: 'active'
    }],
  status: 'active',
};

class MockActions {
  generateId(prefix?: string): string {
    return 'TestId';
  }
}

describe('ListSearchGroupComponent', () => {
  let fixture: ComponentFixture<ListSearchGroupComponent>;
  let comp: ListSearchGroupComponent;

  let mockReduxInst;

  beforeEach(async(() => {
    mockReduxInst = MockNgRedux.getInstance();
    const old = mockReduxInst.getState;
    const wrapped = () => fromJS(old());
    mockReduxInst.getState = wrapped;

    TestBed
      .configureTestingModule({
        declarations: [
          ListSearchGroupComponent,
          ListSearchGroupItemComponent,
          ValidatorErrorsComponent
        ],
        imports: [
          ClarityModule,
          NgxPopperModule,
          ReactiveFormsModule
        ],
        providers: [
          {provide: NgRedux, useValue: mockReduxInst},
          {provide: CohortBuilderService, useValue: {}},
          {provide: CohortSearchActions, useValue: new MockActions()},
        ],
      })
      .compileComponents();
  }));

  beforeEach(() => {
    MockNgRedux.reset();

    fixture = TestBed.createComponent(ListSearchGroupComponent);
    comp = fixture.componentInstance;

    // Default Inputs for tests
    comp.group = group;
    comp.role = 'includes';
    fixture.detectChanges();
  });

  it('Should render', () => {
    // sanity check
    expect(comp).toBeTruthy();
    const items = fixture.debugElement.queryAll(By.css('app-list-search-group-item'));
    expect(items.length).toBe(2);
  });

  it('Should render group count if group count', () => {
    comp.group.count = 25;
    comp.group.isRequesting = false;
    fixture.detectChanges();

    const footer = fixture.debugElement.query(By.css('div.card-footer'));
    const spinner = fixture.debugElement.query(By.css('span.spinner'));
    const text = footer.nativeElement.textContent.replace(/\s+/g, ' ').trim();

    expect(text).toEqual('Temporal Group Count: 25');
    expect(spinner).toBeNull();
  });

  it('Should render a spinner if requesting', () => {
    comp.group.isRequesting = true;
    comp.group.count = 1;
    fixture.detectChanges();
    const spinner = fixture.debugElement.query(By.css('span.spinner'));
    expect(spinner).not.toBeNull();
  });
});