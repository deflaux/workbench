import {NO_ERRORS_SCHEMA} from '@angular/core';
import {async, ComponentFixture, TestBed} from '@angular/core/testing';
import {ClarityModule} from '@clr/angular';
import {NgxPopperModule} from 'ngx-popper';

import {SearchGroupListComponent} from './search-group-list.component';

describe('SearchGroupListComponent', () => {
  let fixture: ComponentFixture<SearchGroupListComponent>;
  let component: SearchGroupListComponent;

  beforeEach(async(() => {
    TestBed
      .configureTestingModule({
        declarations: [
          SearchGroupListComponent,
        ],
        imports: [
          ClarityModule,
          NgxPopperModule,
        ],
        schemas: [ NO_ERRORS_SCHEMA ]
      })
      .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(SearchGroupListComponent);
    component = fixture.componentInstance;

    // Default Inputs for tests
    component.role = 'includes';
    component.groups = [];

    fixture.detectChanges();
  });

  it('Should render', () => {
    expect(component).toBeTruthy();
  });
});
