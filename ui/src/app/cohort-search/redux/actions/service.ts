import {dispatch, NgRedux} from '@angular-redux/store';
import {Injectable} from '@angular/core';
import {fromJS, isImmutable, List, Map, Set} from 'immutable';

import {environment} from 'environments/environment';

import {
  activeGroupId,
  activeItem,
  activeParameterList,
  activeRole,
  CohortSearchState,
  getGroup,
  getItem,
  getSearchRequest,
  groupList,
  includeGroups,
  isAttributeLoading,
  isAutocompleteLoading,
  isCriteriaLoading,
  isRequesting,
  SR_ID,
} from '../store';
import * as ActionFuncs from './creators';

import {
    SearchGroup,
    SearchGroupItem,
    SearchParameter,
    SearchRequest,
    TreeSubType,
    TreeType
} from 'generated';


@Injectable()
export class CohortSearchActions {
  constructor(
    private ngRedux: NgRedux<CohortSearchState>,
  ) {}

  /* We instrument the API calls with the CDR version (which is set in the root
    * component of the Search app and does not change)
    */
  cdrVersionId: number;

  /*
   * Auto-dispatched action creators:
   * We wrap the bare action creators in dispatch here so that we
   * (A) provide a unified action dispatching interface to components and
   * (B) can easily perform multi-step, complex actions from this service
   */
  @dispatch() requestCriteria = ActionFuncs.requestCriteria;
  @dispatch() requestCriteriaBySubtype = ActionFuncs.requestCriteriaBySubtype;
  @dispatch() requestAllCriteria = ActionFuncs.requestAllCriteria;
  @dispatch() requestDrugCriteria = ActionFuncs.requestDrugCriteria;
  @dispatch() loadDemoCriteriaRequestResults = ActionFuncs.loadDemoCriteriaRequestResults;
  @dispatch() cancelCriteriaRequest = ActionFuncs.cancelCriteriaRequest;
  @dispatch() setCriteriaSearchTerms = ActionFuncs.setCriteriaSearchTerms;
  @dispatch() requestAutocompleteOptions = ActionFuncs.requestAutocompleteOptions;
  @dispatch() clearAutocompleteOptions = ActionFuncs.clearAutocompleteOptions;
  @dispatch() requestIngredientsForBrand = ActionFuncs.requestIngredientsForBrand;
  @dispatch() requestAllChildren = ActionFuncs.requestAllChildren;
  @dispatch() selectChildren = ActionFuncs.selectChildren;
  @dispatch() loadCriteriaSubtree = ActionFuncs.loadCriteriaSubtree;
  @dispatch() changeCodeOption = ActionFuncs.changeCodeOption;
  @dispatch() setScrollId = ActionFuncs.setScrollId;

  @dispatch() requestCounts = ActionFuncs.requestCounts;
  @dispatch() _requestAttributePreview = ActionFuncs.requestAttributePreview;
  @dispatch() cancelCountRequest = ActionFuncs.cancelCountRequest;
  @dispatch() setCount = ActionFuncs.loadCountRequestResults;

  @dispatch() _requestPreview = ActionFuncs.requestPreview;

  @dispatch() requestCharts = ActionFuncs.requestCharts;
  @dispatch() cancelChartsRequest = ActionFuncs.cancelChartsRequest;
  @dispatch() setChartData = ActionFuncs.loadChartsRequestResults;

  @dispatch() initGroup = ActionFuncs.initGroup;
  @dispatch() addParameter = ActionFuncs.addParameter;
  @dispatch() removeParameter = ActionFuncs.removeParameter;
  @dispatch() addModifier = ActionFuncs.addModifier;
  @dispatch() removeModifier = ActionFuncs.removeModifier;
  @dispatch() setWizardFocus = ActionFuncs.setWizardFocus;
  @dispatch() clearWizardFocus = ActionFuncs.clearWizardFocus;
  @dispatch() _removeGroup = ActionFuncs.removeGroup;
  @dispatch() _removeGroupItem = ActionFuncs.removeGroupItem;
  @dispatch() requestAttributes = ActionFuncs.requestAttributes;
  @dispatch() loadAttributes = ActionFuncs.loadAttributes;
  @dispatch() hideAttributesPage = ActionFuncs.hideAttributesPage;

  @dispatch() openWizard = ActionFuncs.openWizard;
  @dispatch() reOpenWizard = ActionFuncs.reOpenWizard;
  @dispatch() _finishWizard = ActionFuncs.finishWizard;
  @dispatch() cancelWizard = ActionFuncs.cancelWizard;
  @dispatch() setWizardContext = ActionFuncs.setWizardContext;

  @dispatch() loadEntities = ActionFuncs.loadEntities;
  @dispatch() _resetStore = ActionFuncs.resetStore;

  /** Internal tooling */
  idsInUse = Set<string>();

  generateId(prefix?: string): string {
    prefix = prefix || 'id';
    let newId = `${prefix}_${this.genSuffix()}`;
    while (this.idsInUse.has(newId)) {
      newId = `${prefix}_${this.genSuffix()}`;
    }
    this.addId(newId);
    return newId;
  }

  genSuffix(): string {
    return Math.random().toString(36).substr(2, 9);
  }

  removeId(id: string): void {
    this.idsInUse = this.idsInUse.delete(id);
  }

  addId(newId: string): void {
    this.idsInUse = this.idsInUse.add(newId);
  }

  get state() {
    return this.ngRedux.getState();
  }

  debugDir(obj) {if (environment.debug) { console.dir(obj); }}
  debugLog(msg) {if (environment.debug) { console.log(msg); }}


  /* Higher order actions - actions composed of other actions or providing
   * alternate interfaces for a simpler action.
   */
  finishWizard(): void {
    const role = activeRole(this.state);
    const groupId = activeGroupId(this.state);
    const itemId = activeItem(this.state).get('id');
    const selections = activeParameterList(this.state);
    this._finishWizard();

    if (!selections.isEmpty()) {
      this.requestItemCount(role, itemId);
      this.requestGroupCount(role, groupId);
      this.requestTotalCount(groupId);
    }
  }

  cancelIfRequesting(kind, id): void {
    if (isRequesting(kind, id)(this.state)) {
      this.cancelCountRequest(kind, id);
    }
  }

  removeGroup(role: keyof SearchRequest, groupId: string): void {
    const group = getGroup(groupId)(this.state);
    this.debugLog(`Removing ${groupId} of ${role}:`);
    this.debugDir(group);

    this.cancelIfRequesting('groups', groupId);

    this._removeGroup(role, groupId);
    this.removeId(groupId);

    group.get('items', List()).forEach(itemId => {
      this.cancelIfRequesting('items', itemId);
      this._removeGroupItem(groupId, itemId);
      this.removeId(itemId);
    });

    const hasItems = !group.get('items', List()).isEmpty();
    if (hasItems) {
      this.requestTotalCount();
    }
  }

  removeGroupItem(role: keyof SearchRequest, groupId: string, itemId: string): void {
    const item = getItem(itemId)(this.state);
    const hasItems = !item.get('searchParameters', List()).isEmpty();
    const countIsNonZero = item.get('count') !== 0;
    // The optimization wherein we only fire the request if the item
    // has a non-zero count (i.e. it affects its group and hence the total
    // counts) ONLY WORKS if the item is NOT an only child.
    const isOnlyChild = (getGroup(groupId)(this.state))
      .get('items', List())
      .equals(List([itemId]));

    this.debugLog(`Removing ${itemId} of ${groupId}:`);
    this.debugDir(item);
    this.debugLog(
      `hasItems: ${hasItems}, countIsNonZero: ${countIsNonZero}, isOnlyChild: ${isOnlyChild}`
    );

    this.cancelIfRequesting('items', itemId);
    this._removeGroupItem(groupId, itemId);
    this.removeId(itemId);

    if (hasItems && (countIsNonZero || isOnlyChild)) {
      this.requestTotalCount();

      /* If this was the only item in the group, the group no longer has a
       * count, not really. */
      if (isOnlyChild) {
        this.removeGroup(role, groupId);
      } else {
        this.requestGroupCount(role, groupId);
      }
    }
  }

  fetchCriteria(kind: string, parentId: number): void {
    const isLoading = isCriteriaLoading(kind, parentId)(this.state);
    const isLoaded = this.state.getIn(['criteria', 'tree', kind, parentId]);
    if (isLoaded || isLoading) {
      return;
    }
    this.requestCriteria(this.cdrVersionId, kind, parentId);
  }

  fetchCriteriaBySubtype(kind: string, subtype: string, parentId: number): void {
    const isLoading = isCriteriaLoading(kind, parentId)(this.state);
    const isLoaded = this.state.getIn(['criteria', 'tree', kind, subtype, parentId]);
    if (isLoaded || isLoading) {
      return;
    }
    this.requestCriteriaBySubtype(this.cdrVersionId, kind, subtype, parentId);
  }

  fetchAllCriteria(kind: string, parentId: number): void {
    const isLoading = isCriteriaLoading(kind, parentId)(this.state);
    const isLoaded = this.state.getIn(['criteria', 'tree', kind, parentId]);
    if (isLoaded || isLoading) {
      return;
    }
    this.requestAllCriteria(this.cdrVersionId, kind, parentId);
  }

  fetchDrugCriteria(kind: string, parentId: number, subtype: string): void {
    const isLoading = isCriteriaLoading(kind, parentId)(this.state);
    const isLoaded = this.state.getIn(['criteria', 'tree', kind, parentId]);
    if (isLoaded || isLoading) {
      return;
    }
    this.requestDrugCriteria(this.cdrVersionId, kind, parentId, subtype);
  }

  fetchAutocompleteOptions(kind: string, subtype: string, terms: string): void {
    this.requestAutocompleteOptions(this.cdrVersionId, kind, subtype, terms);
  }

  fetchIngredientsForBrand(conceptId: number): void {
    const isLoading = isAutocompleteLoading()(this.state);
    if (isLoading) {
      return;
    }
    this.requestIngredientsForBrand(this.cdrVersionId, conceptId);
  }

  fetchAllChildren(node: any): void {
    const kind = node.get('type');
    const id = node.get('id');
    if (kind === TreeType[TreeType.DRUG]) {
      this.requestAllChildren(this.cdrVersionId, kind, id);
    } else {
      const paramId = `param${node.get('conceptId') ? node.get('conceptId') : id}`;
      const param = node.set('parameterId', paramId);
      this.addParameter(param);
      this.selectChildren(kind, id);
    }
  }

  fetchAttributes(node: any): void {
    const isLoading = isAttributeLoading()(this.state);
    if (isLoading) {
      return;
    }
    this.requestAttributes(this.cdrVersionId, node);
  }

  requestPreview(): void {
    const params = activeParameterList(this.state)
      .valueSeq()
      .map(this.mapParameter)
      .toJS();
    const item = activeItem(this.state);
    this._requestPreview(this.cdrVersionId, <SearchRequest>{
      includes: [],
      excludes: [],
      [activeRole(this.state)]: [{
        items: [<SearchGroupItem>{
          id: item.get('paramId'),
          type: item.get('type', '').toUpperCase(),
          searchParameters: params,
          modifiers: item.get('modifiers', List()).toJS(),
        }]
      }]
    });
  }

  requestAttributePreview(param: any): void {
    const role = activeRole(this.state);
    const itemId = activeItem(this.state).get('id');
    const searchParam = [this.mapParameter(param)];
    const groupItem = <SearchGroupItem>{
      id: itemId,
      type: searchParam[0].type,
      searchParameters: searchParam,
      modifiers: [],
    };
    const request = <SearchRequest>{
      includes: [],
      excludes: [],
      [role]: [{
        items: [groupItem],
      }]
    };
    this._requestAttributePreview(this.cdrVersionId, request);
  }

  requestItemCount(role: keyof SearchRequest, itemId: string): void {
    const item = getItem(itemId)(this.state);
    if (item.get('isRequesting', false)) {
      this.cancelCountRequest('items', itemId);
    }
    const request = <SearchRequest>{
      includes: [],
      excludes: [],
      [role]: [{
        items: [this.mapGroupItem(itemId)],
      }]
    };
    this.requestCounts(this.cdrVersionId, 'items', itemId, request);
  }

  requestGroupCount(role: keyof SearchRequest, groupId: string): void {
    const group = getGroup(groupId)(this.state);
    if (group.get('isRequesting', false)) {
      this.cancelCountRequest('groups', groupId);
    }
    const request = <SearchRequest>{
      includes: [],
      excludes: [],
      [role]: [this.mapGroup(groupId)]
    };
    this.requestCounts(this.cdrVersionId, 'groups', groupId, request);
  }

  /**
   * @param outdatedGroup: string
   */
  requestTotalCount(outdatedGroupId?: string): void {
    const searchRequest = getSearchRequest(SR_ID)(this.state);
    if (searchRequest.get('isRequesting', false)) {
      this.cancelChartsRequest('searchRequests', SR_ID);
    }

    const included = includeGroups(this.state);
    this.debugLog('Making a request for Total with included groups: ');
    this.debugDir(included);

    /* If there are no members of an intersection, the intersection is the null
     * set
     */
    const noGroups = included.size === 0;
    const noGroupsWithItems = included.every(group => group.get('items').size === 0);
    const emptyIntersection = noGroups || noGroupsWithItems;

    /* If any member of an intersection is the null set, the intersection is
     * the null set - unless the member in question is itself outdated (i.e.
     * the group with a zero count is itself being updated concurrently with
     * the totals, so the ocunt may not actually be zero anymore)
     */
    const nullIntersection = included
      .filterNot(group => group.get('id') === outdatedGroupId)
      .some(group => group.get('count') === 0);

    /* In either case the total count is provably zero without needing to ask
     * the API
     */
    if (nullIntersection || emptyIntersection) {
      this.debugLog('Not making request');
      this.setChartData('searchRequests', SR_ID, []);
      return ;
    }

    const request = this.mapAll();
    this.requestCharts(this.cdrVersionId, 'searchRequests', SR_ID, request);
  }

  /*
   * Iterates through the full state object, re-running all count / chart
   * requests
   */
  runAllRequests() {
    const doRequests = (kind) => {
      const groups = groupList(kind)(this.state);
      groups.forEach(group => {
        group.get('items', List()).forEach(itemId => {
          this.requestItemCount(kind, itemId);
        });
        this.requestGroupCount(kind, group.get('id'));
      });
    };
    doRequests('includes');
    doRequests('excludes');

    /* Since everything is being run again, the optimizations in
     * `this.requestTotalCount` are sure to be off.  Basically ALL the groups
     * are outdated at the time this runs */
    const request = this.mapAll();
    this.requestCharts(this.cdrVersionId, 'searchRequests', SR_ID, request);
  }

  mapAll = (): SearchRequest => {
    const getGroups = kind =>
      (getSearchRequest(SR_ID)(this.state))
        .get(kind, List())
        .map(this.mapGroup)
        // By this point, unlike almost everywhere else, we're back in vanilla JS land
        .filterNot(grp => grp.items.length === 0)
        .toJS();

    const includes = getGroups('includes');
    const excludes = getGroups('excludes');

    return <SearchRequest>{includes, excludes};
  }

  mapGroup = (groupId: string): SearchGroup => {
    const group = getGroup(groupId)(this.state);
    let items = group.get('items', List()).map(this.mapGroupItem);
    if (isImmutable(items)) {
      items = items.toJS();
    }
    return <SearchGroup>{id: groupId, items};
  }

  mapGroupItem = (itemId: string): SearchGroupItem => {
    const item = getItem(itemId)(this.state);
    const critIds = item.get('searchParameters', List());

    const params = this.state
      .getIn(['entities', 'parameters'], Map())
      .filter((_, key) => critIds.includes(key))
      .valueSeq()
      .map(this.mapParameter)
      .toJS();

    return <SearchGroupItem>{
      id: itemId,
      type: item.get('type', '').toUpperCase(),
      searchParameters: params,
      modifiers: item.get('modifiers', List()).toJS(),
    };
  }

  mapParameter = (immParam): SearchParameter => {
    const param = <SearchParameter>{
      parameterId: immParam.get('parameterId'),
      name: immParam.get('name', ''),
      value: TreeSubType[TreeSubType.DEC] === immParam.get('subtype')
          ? immParam.get('name') : immParam.get('code'),
      type: immParam.get('type', ''),
      subtype: immParam.get('subtype', ''),
      group: immParam.get('group'),
      attributes: immParam.get('attributes')
    };

    if (param.type === TreeType[TreeType.DEMO]
      || param.type === TreeType[TreeType.VISIT]
      || param.type === TreeType[TreeType.PM]
      || param.type === TreeType[TreeType.MEAS]
      || param.type === TreeType[TreeType.DRUG]
      || param.type === TreeType[TreeType.ICD9]
      || param.type === TreeType[TreeType.ICD10]
      || param.type === TreeType[TreeType.CPT]
      || param.type === TreeType[TreeType.CONDITION]) {
        param.conceptId = immParam.get('conceptId');
    }
    if (param.type === TreeType[TreeType.ICD9]
      || param.type === TreeType[TreeType.ICD10]
      || param.type === TreeType[TreeType.CPT]
      || param.type === TreeType[TreeType.CONDITION]) {
        param.domain = immParam.get('domainId');
    }

    return param;
  }

  /*
   * Deserializes a JSONified SearchRequest into an entities object
   */
  deserializeEntities(jsonStore: string): Map<any, any> {
    const data = JSON.parse(jsonStore);
    const entities = {
      searchRequests: {
        [SR_ID]: {
          includes: data.includes.map(g => g.id),
          excludes: data.excludes.map(g => g.id),
        }
      },
      groups: {},
      items: {},
      parameters: {},
    };

    for (const role of ['includes', 'excludes']) {
      entities.searchRequests[SR_ID][role] = data[role].map(group => {
        group.items = group.items.map(item => {
          item.searchParameters = item.searchParameters.map(param => {
            param.code = param.value;
            param.hasAttributes = param.attributes.length > 0;
            entities.parameters[param.parameterId] = param;
            this.addId(param.parameterId);
            return param.parameterId;
          });
          item.count = 0;
          item.isRequesting = false;
          entities.items[item.id] = item;
          this.addId(item.id);
          return item.id;
        });
        group.count = 0;
        group.isRequesting = false;
        entities.groups[group.id] = group;
        this.addId(group.id);
        return group.id;
      });
    }
    return fromJS(entities);
  }

  /*
   * Reset the ID cache, then
   * Loads a JSONified SearchRequest into the store
   */
  loadFromJSON(json: string): void {
    this.idsInUse = Set<string>();
    const entities = this.deserializeEntities(json);
    this.loadEntities(entities);
  }

  /*
   * Reset Store: reset the store to the initial state and wipe all cached ID's
   */
  resetStore(): void {
    this.idsInUse = Set<string>();
    this._resetStore();
  }
}
