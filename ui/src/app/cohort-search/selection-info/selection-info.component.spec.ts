import {NgRedux} from '@angular-redux/store';
import {MockNgRedux} from '@angular-redux/store/testing';
import {async, ComponentFixture, TestBed} from '@angular/core/testing';
import {ClarityModule} from '@clr/angular';
import {CohortSearchActions} from 'app/cohort-search/redux';
import {fromJS} from 'immutable';
import {NgxPopperModule} from 'ngx-popper';
import {SelectionInfoComponent} from './selection-info.component';

describe('SelectionInfoComponent', () => {
  let component: SelectionInfoComponent;
  let fixture: ComponentFixture<SelectionInfoComponent>;
  let mockReduxInst;

  beforeEach(async(() => {
    mockReduxInst = MockNgRedux.getInstance();
    const _old = mockReduxInst.getState;
    const _wrapped = () => fromJS(_old());
    mockReduxInst.getState = _wrapped;

    TestBed.configureTestingModule({
      declarations: [SelectionInfoComponent],
      imports: [ClarityModule, NgxPopperModule],
      providers: [
        {provide: NgRedux, useValue: mockReduxInst},
        CohortSearchActions,
      ],
    })
      .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(SelectionInfoComponent);
    component = fixture.componentInstance;
    component.parameter = fromJS({
      code: '',
      conceptId: 903133,
      count: 0,
      domainId: 'Measurement',
      group: false,
      hasAttributes: true,
      id: 316305,
      name: 'Height Detail',
      parameterId: 'param316305',
      parentId: 0,
      predefinedAttributes: null,
      selectable: true,
      subtype: 'HEIGHT',
      type: 'PM'
    });
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

});
