import {Component, ViewChild} from '@angular/core';
import {ActivatedRoute} from '@angular/router';
import {ConceptSet, ConceptsService, DomainInfo} from '../../../generated';
import {ConceptSetsService} from '../../../generated/api/conceptSets.service';
@Component({
  selector: 'app-create-conceptset-modal',
  styleUrls: [
    '../../styles/buttons.css',
    '../../styles/inputs.css',
    '../../styles/errors.css',
    './component.css'
  ],
  templateUrl: './component.html',
})
export class CreateConceptSetModalComponent {
  public modalOpen  = false;
  wsNamespace: string;
  wsId: string;
  name: string;
  description: string;
  domain: any;
  conceptDomainList: Array<DomainInfo> = [];
  required = false;
  alreadyExist = false;

  constructor(private conceptsService: ConceptsService,
              private conceptSetService: ConceptSetsService,
              private route: ActivatedRoute) {
    this.wsNamespace = this.route.snapshot.params['ns'];
    this.wsId = this.route.snapshot.params['wsid'];
  }

  open(): void {
    this.required = false;
    this.alreadyExist = false;
    this.reset();
    this.conceptsService
        .getDomainInfo(this.wsNamespace, this.wsId)
        .subscribe((response) => {
      this.conceptDomainList = response.items;
      this.domain = this.conceptDomainList[0];
    });
      this.modalOpen = true;
  }

  close(): void {
    this.modalOpen = false;
  }

  private reset(): void {
    this.name = '';
    this.description = '';
    this.domain = '';
    this.alreadyExist = false;
    this.required = false;
  }

  save(): void {
    this.required = false;
    this.alreadyExist = false;

    if (!this.name) {
      this.required = true;
      return;
    }
    const concepts: ConceptSet = {
      name: this.name,
      description: this.description,
      domain: this.domain
    };
    this.conceptSetService.createConceptSet(this.wsNamespace, this.wsId, concepts)
        .subscribe((response) => {
      this.modalOpen = false;
    }, () => {
          this.alreadyExist = true;
        });
  }
}

