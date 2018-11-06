import {Component, OnDestroy, OnInit, ViewChild} from '@angular/core';
import {ActivatedRoute, Router} from '@angular/router';
import {ProfileStorageService} from 'app/services/profile-storage.service';
import {hasRegisteredAccess} from 'app/utils';
import {BugReportComponent} from 'app/views/bug-report/component';
import {QuickTourModalComponent} from 'app/views/quick-tour-modal/component';
import {RecentWorkComponent} from 'app/views/recent-work/component';

import {
  BillingProjectStatus,
  DataAccessLevel,
  IdVerificationStatus,
  PageVisit,
  Profile,
  ProfileService
} from 'generated';

@Component({
  styleUrls: ['./component.css'],
  templateUrl: './component.html',
})

export class HomepageComponent implements OnInit, OnDestroy {
  private static pageId = 'homepage';
  profile: Profile;
  view: any[] = [180, 180];
  numberOfTotalTasks = 4;
  completedTasksName = 'Completed';
  unfinishedTasksName = 'Unfinished';
  spinnerValues = [
    {
      'name': this.completedTasksName,
      'value': this.completedTasks
    },
    {
      'name': this.unfinishedTasksName,
      'value': this.numberOfTotalTasks - this.completedTasks
    }
  ];
  billingProjectInitialized = false;
  billingProjectQuery: NodeJS.Timer;
  firstSignIn: Date;
  firstVisit = true;
  newPageVisit: PageVisit = { page: HomepageComponent.pageId};
  footerLinks = [
    {
      title: 'Working Within Researcher Workbench',
      links: ['Researcher Workbench Mission',
        'User interface components',
        'What to do when things go wrong',
        'Contributing to the Workbench']
    },
    {
      title: 'Workspace',
      links: ['Workspace interface components',
        'User interface components',
        'Collaborating with other researchers',
        'Sharing and Publishing Workspaces']
    },
    {
      title: 'Working with Notebooks',
      links: ['Notebook interface components',
        'Notebooks and data',
        'Collaborating with other researchers',
        'Sharing and Publishing Notebooks']
    }];
  @ViewChild(BugReportComponent)
  bugReportComponent: BugReportComponent;
  @ViewChild(QuickTourModalComponent)
  quickTourModal: QuickTourModalComponent;

  constructor(
    private profileService: ProfileService,
    private profileStorageService: ProfileStorageService,
    private route: ActivatedRoute,
    private router: Router,
  ) {}

  ngOnInit(): void {
    this.profileService.getMe().subscribe(profile => {
      if (profile.pageVisits) {
        this.firstVisit = !profile.pageVisits.some(v =>
        v.page === HomepageComponent.pageId);
      }
    },
      e => {},
      () => {
      if (this.firstVisit) {
        this.openQuickTour();
      }
        this.profileService.updatePageVisits(this.newPageVisit).subscribe();
      });
    this.profileStorageService.profile$.subscribe((profile) => {
      // This will block workspace creation until the billing project is initialized
      if (profile.freeTierBillingProjectStatus === BillingProjectStatus.Ready) {
        this.billingProjectInitialized = true;
      } else {
        this.billingProjectQuery = setTimeout(() => {
          this.profileStorageService.reload();
        }, 10000);
      }
      this.profile = profile;
      this.reloadSpinner();
    });
    this.profileStorageService.reload();
  }

  openQuickTour(): void {
    this.quickTourModal.open();
  }

  public get completedTasks() {
    let completedTasks = 0;
    if (this.profile === undefined) {
      return completedTasks;
    }
    if (this.profile.idVerificationStatus === IdVerificationStatus.VERIFIED) {
      completedTasks += 1;
    }
    if (this.profile.demographicSurveyCompletionTime !== null) {
      completedTasks += 1;
    }
    if (this.profile.ethicsTrainingCompletionTime !== null) {
      completedTasks += 1;
    }
    if (this.profile.termsOfServiceCompletionTime !== null) {
      completedTasks += 1;
    }
    return completedTasks;
  }

  public get completedTasksAsPercentage() {
    return this.completedTasks / this.numberOfTotalTasks * 100;
  }

  reloadSpinner(): void {
    this.spinnerValues = [
      {
        'name': this.completedTasksName,
        'value': this.completedTasks
      },
      {
        'name': this.unfinishedTasksName,
        'value': this.numberOfTotalTasks - this.completedTasks
      }
    ];
  }

  ngOnDestroy(): void {
    clearTimeout(this.billingProjectQuery);
  }

  addWorkspace(): void {
    this.router.navigate(['workspaces/build'], {relativeTo : this.route});
  }

  navigateToProfile(): void {
   this.router.navigate(['profile']);
  }

  listWorkspaces(): void {
   this.router.navigate(['workspaces']);
  }

  get twoFactorBannerEnabled() {
    if (this.firstSignIn == null) {
      return false;
    }
    // Don't show the banner after 1 week as their account would
    // have been disabled had they not enabled 2-factor auth.
    return !(new Date().getTime() - this.firstSignIn.getTime() > 7 * 24 * 60 * 60 * 1000);
  }
}
