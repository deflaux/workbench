import {Component, OnInit, ViewChild} from '@angular/core';
import {ActivatedRoute} from '@angular/router';
import {ConceptSetsService} from '../../../generated/api/conceptSets.service';
import {CreateConceptSetModalComponent
} from '../conceptset-create-modal/component';

@Component({
  styleUrls: [
    '../../styles/cards.css'],
  templateUrl: './component.html',
})
export class ConceptsListComponent implements OnInit {
  wsNamespace: string;
  wsId: string;
  concept: any[] = [];

  constructor(private conceptsService: ConceptSetsService,
              private route: ActivatedRoute) {
  this.wsNamespace = this.route.snapshot.params['ns'];
  this.wsId = this.route.snapshot.params['wsid'];
}

  @ViewChild(CreateConceptSetModalComponent)
  conceptCreateModal: CreateConceptSetModalComponent;

  addConcept() {
   this.conceptCreateModal.open();
  }

  ngOnInit() {
 this.conceptsService.getConceptSetsInWorkspace(this.wsNamespace, this.wsId)
       .subscribe((response) => {
     this.concept = response.items;
   });
  }
}
