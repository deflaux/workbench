import {Component, Input} from '@angular/core';

import {Participant} from 'app/cohort-review/participant.model';

@Component({
  selector: 'app-sidebar-content',
  templateUrl: './sidebar-content.component.html',
  styleUrls: ['./sidebar-content.component.css']
})
export class SidebarContentComponent {
  @Input() participant: Participant;
}
