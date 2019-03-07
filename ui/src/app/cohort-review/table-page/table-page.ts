import {Component, OnDestroy, OnInit} from '@angular/core';
import {ClrDatagridStateInterface} from '@clr/angular';
import * as fp from 'lodash/fp';
import {Subscription} from 'rxjs/Subscription';

import {ClearButtonFilterComponent} from 'app/cohort-review/clearbutton-filter/clearbutton-filter.component';
import {MultiSelectFilterComponent} from 'app/cohort-review/multiselect-filter/multiselect-filter.component';
import {Participant} from 'app/cohort-review/participant.model';
import {cohortReviewStore} from 'app/cohort-review/review-state.service';
import {currentCohortStore, currentWorkspaceStore, urlParamsStore} from 'app/utils/navigation';

import {ParticipantCohortStatusColumns} from 'generated';
import {
  CohortBuilderService,
  CohortReview,
  CohortReviewService,
  Filter,
  Operator,
  PageFilterType,
  ParticipantCohortStatusColumns as Columns,
  ParticipantCohortStatuses as Request,
  SortOrder,
} from 'generated';

function isMultiSelectFilter(filter): filter is MultiSelectFilterComponent {
  return (filter instanceof MultiSelectFilterComponent);
}

function isClearButtonFilter(filter): filter is ClearButtonFilterComponent {
  return (filter instanceof ClearButtonFilterComponent);
}


@Component({
  templateUrl: './table-page.html',
  styleUrls: [
    './table-page.css',
  ],
})
export class TablePage implements OnInit, OnDestroy {

  readonly ColumnEnum = Columns;
  readonly ReverseColumnEnum = {
    participantId: Columns.PARTICIPANTID,
    gender: Columns.GENDER,
    race: Columns.RACE,
    ethnicity: Columns.ETHNICITY,
    birthDate: Columns.BIRTHDATE,
    status: Columns.STATUS
  };

  participants: Participant[];

  review: CohortReview;
  loading: boolean;
  subscription: Subscription;
  genders: string[] = [];
  races: string[] = [];
  ethnicities: string[] = [];
  isFiltered = [];
  cohortName: string;
  totalParticipantCount: number;
  tab = 'participants';
  reportInit = false;

  constructor(
    private reviewAPI: CohortReviewService,
    private builderAPI: CohortBuilderService,
  ) {}

  ngOnInit() {
    this.loading = false;
    this.cohortName = currentCohortStore.getValue().name;
    this.subscription = cohortReviewStore.subscribe(review => {
      this.review = review;
      this.participants = review.participantCohortStatuses.map(Participant.fromStatus);
      this.totalParticipantCount = review.matchedParticipantCount;
    });

    const cdrid = +(currentWorkspaceStore.getValue().cdrVersionId);
    this.builderAPI.getParticipantDemographics(cdrid).subscribe(data => {
      const extract = arr => fp.uniq(arr.map(i => i.conceptName)) as string[];
      this.races = extract(data.raceList);
      this.genders = extract(data.genderList);
      this.ethnicities = extract(data.ethnicityList);
    });
  }



  refresh(state: ClrDatagridStateInterface) {
    setTimeout(() => this.loading = true, 0);
    console.log('Datagrid state: ');
    console.dir(state);

    /* Populate the query with page / pagesize and then defaults */
    const query = <Request>{
      page: Math.floor(state.page.from / state.page.size),
      pageSize: state.page.size,
      sortColumn: Columns.PARTICIPANTID,
      sortOrder: SortOrder.Asc,
      filters: {items: []},
      pageFilterType: PageFilterType.ParticipantCohortStatuses,
    };

    if (state.sort) {
      const sortby = <string>(state.sort.by);
      query.sortColumn = this.ReverseColumnEnum[sortby];
      query.sortOrder = state.sort.reverse
        ? SortOrder.Desc
        : SortOrder.Asc;
    }

    this.isFiltered = [];
    if (state.filters) {
      for (const filter of state.filters) {
        if (isMultiSelectFilter(filter)) {
          const property = filter.property;
          this.isFiltered.push(property);

          const operator = Operator.IN;
          query.filters.items.push(<Filter>{property, values: filter.selection.value, operator});
        } else if (isClearButtonFilter(filter)) {
          const property = filter.property;
          this.isFiltered.push(property);
          let operator = Operator.EQUAL;
          if (filter.property === ParticipantCohortStatusColumns.PARTICIPANTID ||
            filter.property === ParticipantCohortStatusColumns.BIRTHDATE) {
            operator = Operator.LIKE;
          }
          query.filters.items.push(<Filter>{property, values: [filter.selection.value], operator});
        } else {
          const {property, value} = <any>filter;
          const operator = Operator.EQUAL;
          query.filters.items.push(<Filter>{property, values: [value], operator});
        }
      }
    }

    const {ns, wsid, cid} = urlParamsStore.getValue();
    const cdrid = +(currentWorkspaceStore.getValue().cdrVersionId);

    console.log('Participant page request parameters:');
    console.dir(query);

    return this.reviewAPI
      .getParticipantCohortStatuses(ns, wsid, cid, cdrid, query)
      .do(_ => this.loading = false)
      .subscribe(review => {
        cohortReviewStore.next(review);
      });
  }

  isSelected(column: string) {
    return this.isFiltered.indexOf(column) > -1;
  }

  ngOnDestroy() {
    this.subscription.unsubscribe();
  }

  setTab(tab: string) {
    this.tab = tab;
    if (tab === 'report' && !this.reportInit) {
      this.reportInit = true;
    }
  }
}
