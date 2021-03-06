/* tslint:disable:max-line-length */
import {CommonModule} from '@angular/common';
import {NgModule} from '@angular/core';
import {ReactiveFormsModule} from '@angular/forms';
import {ClarityModule} from '@clr/angular';
import {ChartModule} from 'angular2-highcharts';
import {HighchartsStatic} from 'angular2-highcharts/dist/HighchartsService';
import * as highCharts from 'highcharts';
import {NgxPopperModule} from 'ngx-popper';

/* Pages */
import {CohortCommonModule} from 'app/cohort-common/module';
import {CreateReviewModalComponent} from './create-review-modal/create-review-modal';
import {DetailPageComponent} from './detail-page/detail-page';
import {PageLayout} from './page-layout/page-layout';
import {QueryReportComponent} from './query-report/query-report.component';
import {CohortReviewRoutingModule} from './routing/routing.module';
import {TablePage} from './table-page/table-page';


/* tslint:enable:max-line-length */

@NgModule({
  imports: [
    // Angular
    CommonModule,
    ReactiveFormsModule,
    // Routes
    CohortReviewRoutingModule,
    // 3rd Party
    ClarityModule,
    NgxPopperModule,
    ChartModule,
    // Ours
    CohortCommonModule,

  ],
  declarations: [
    /* Scaffolding and Pages */
    CreateReviewModalComponent,
    DetailPageComponent,
    PageLayout,
    QueryReportComponent,
    TablePage,
  ],
  providers: [
    {
      provide: HighchartsStatic,
      useValue: highCharts
    },
  ]
})
export class CohortReviewModule {}
