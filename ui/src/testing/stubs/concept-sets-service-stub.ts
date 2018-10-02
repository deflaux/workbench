import {Response, ResponseOptions} from '@angular/http';
import {Observable} from 'rxjs/Observable';

import {
  ConceptSetListResponse
} from 'generated';
import {ConceptSet} from '../../generated/model/conceptSet';

export class ConceptSetsServiceStub {

  constructor() {}

  public getConceptSetsInWorkspace(
    workspaceNamespace: string, workspaceId: string): Observable<ConceptSetListResponse> {
      return new Observable<ConceptSetListResponse>(observer => {
        setTimeout(() => {
          observer.next({items: []});
          observer.complete();
        }, 0);
      });
  }

  public createConceptSet(
      workspaceNamespace: string, workspaceId: string, conceptSet?: ConceptSet)
  : Observable<ConceptSet> {
    return new Observable<ConceptSet>(observer => {
      setTimeout(() => {
        observer.next(null);
        observer.complete();
      }, 0);
    });
  }
}
