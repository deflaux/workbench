import { Component } from '@angular/core';
import { async, ComponentFixture, TestBed } from '@angular/core/testing';
import {By} from '@angular/platform-browser';

import { HighlightSearchComponent } from './highlight-search.component';

describe('HighlightSearchComponent', () => {
  let fixture: ComponentFixture<TestHighlightComponent>;
  beforeEach(async(() => {
    TestBed.configureTestingModule({
      declarations: [
        HighlightSearchComponent,
        TestHighlightComponent
      ]
      })
      .compileComponents();
  }));

  beforeEach(() => {
    fixture = TestBed.createComponent(TestHighlightComponent);
    fixture.detectChanges();
  });

  it('should highlight search terms', () => {
    const tokens = fixture.debugElement.queryAll(By.css('.noExtraSpace'));
    // TODO: Ideally make some asserations about t.nativeElement.textContent
    // for t in tokens. But what's actually expected here?
  });

  @Component({
    template: '<app-highlight-search ' +
      '[text]="\'lung enlargement with_another disorder_foo\'" ' +
      '[searchTerm]="\'lung disorder\'"></app-highlight-search>'
  })
  class TestHighlightComponent {}
});
