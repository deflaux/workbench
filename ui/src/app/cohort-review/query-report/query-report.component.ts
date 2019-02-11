import {AfterContentChecked, ChangeDetectorRef, Component, OnInit} from '@angular/core';
import {ActivatedRoute} from '@angular/router';
import {WorkspaceData} from 'app/resolvers/workspace';
import {CdrVersionStorageService} from 'app/services/cdr-version-storage.service';
import {currentCohortStore, currentWorkspaceStore} from 'app/utils/navigation';
import {CohortBuilderService, Workspace} from 'generated';
import {List} from 'immutable';
import {Observable} from 'rxjs/Observable';




@Component({
  selector: 'app-query-report',
  templateUrl: './query-report.component.html',
  styleUrls: ['./query-report.component.css']
})
export class QueryReportComponent implements OnInit, AfterContentChecked {
  cohort: any;
  review: any;
  cdrDetails: any ;
  data:  Observable<List<any>>;
  workspace: Workspace;

  constructor(private api: CohortBuilderService,
    private route: ActivatedRoute,
    private cdref: ChangeDetectorRef,
    private cdrVersionStorageService: CdrVersionStorageService) {}

  ngOnInit() {
    const {review} = this.route.snapshot.data;
    this.cohort = currentCohortStore.getValue();
    this.workspace = currentWorkspaceStore.getValue();
    this.review = review;
    this.cdrVersionStorageService.cdrVersions$.subscribe(resp => {
      this.cdrDetails = resp.items.find(v => v.cdrVersionId === this.workspace.cdrVersionId);
    });
  }

  ngAfterContentChecked() {
    this.cdref.detectChanges();
  }

  getDemoChartData(d) {
    this.ngAfterContentChecked();
    if (d) {
      this.data = d.toJS();
    }
  }
}
