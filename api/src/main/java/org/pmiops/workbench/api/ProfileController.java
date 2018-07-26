package org.pmiops.workbench.api;

import com.google.common.collect.ImmutableMap;

import java.sql.Timestamp;
import java.time.Clock;
import java.util.ArrayList;
import java.util.List;
import java.util.ListIterator;
import java.util.Map;
import java.util.Optional;
import java.util.Properties;
import java.util.function.Function;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import javax.inject.Provider;
import javax.mail.Message;
import javax.mail.MessagingException;
import javax.mail.Session;
import javax.mail.internet.AddressException;
import javax.mail.internet.InternetAddress;
import javax.mail.internet.MimeMessage;

import org.pmiops.workbench.annotations.AuthorityRequired;
import org.pmiops.workbench.auth.ProfileService;
import org.pmiops.workbench.auth.UserAuthentication;
import org.pmiops.workbench.auth.UserAuthentication.UserType;
import org.pmiops.workbench.config.WorkbenchConfig;
import org.pmiops.workbench.config.WorkbenchEnvironment;
import org.pmiops.workbench.db.dao.UserDao;
import org.pmiops.workbench.db.dao.UserService;
import org.pmiops.workbench.db.model.User;
import org.pmiops.workbench.exceptions.BadRequestException;
import org.pmiops.workbench.exceptions.ConflictException;
import org.pmiops.workbench.exceptions.EmailException;
import org.pmiops.workbench.exceptions.ForbiddenException;
import org.pmiops.workbench.exceptions.GatewayTimeoutException;
import org.pmiops.workbench.exceptions.ServerErrorException;
import org.pmiops.workbench.exceptions.WorkbenchException;
import org.pmiops.workbench.firecloud.FireCloudService;
import org.pmiops.workbench.firecloud.model.BillingProjectMembership.CreationStatusEnum;
import org.pmiops.workbench.google.CloudStorageService;
import org.pmiops.workbench.google.DirectoryService;
import org.pmiops.workbench.mail.MailService;
import org.pmiops.workbench.model.Authority;
import org.pmiops.workbench.model.BillingProjectMembership;
import org.pmiops.workbench.model.BillingProjectStatus;
import org.pmiops.workbench.model.ContactEmailTakenResponse;
import org.pmiops.workbench.model.CreateAccountRequest;
import org.pmiops.workbench.model.EmailVerificationStatus;
import org.pmiops.workbench.model.IdVerificationListResponse;
import org.pmiops.workbench.model.IdVerificationReviewRequest;
import org.pmiops.workbench.model.IdVerificationStatus;
import org.pmiops.workbench.model.InstitutionalAffiliation;
import org.pmiops.workbench.model.InvitationVerificationRequest;
import org.pmiops.workbench.model.Profile;
import org.pmiops.workbench.model.ResendWelcomeEmailRequest;
import org.pmiops.workbench.model.UpdateContactEmailRequest;
import org.pmiops.workbench.model.UsernameTakenResponse;
import org.pmiops.workbench.notebooks.NotebooksService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.orm.ObjectOptimisticLockingFailureException;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class ProfileController implements ProfileApiDelegate {
  private static final Map<CreationStatusEnum, BillingProjectStatus> fcToWorkbenchBillingMap =
      new ImmutableMap.Builder<CreationStatusEnum, BillingProjectStatus>()
          .put(CreationStatusEnum.CREATING, BillingProjectStatus.PENDING)
          .put(CreationStatusEnum.READY, BillingProjectStatus.READY)
          .put(CreationStatusEnum.ERROR, BillingProjectStatus.ERROR)
          .build();
  private static final Function<org.pmiops.workbench.firecloud.model.BillingProjectMembership,
      BillingProjectMembership> TO_CLIENT_BILLING_PROJECT_MEMBERSHIP =
      new Function<org.pmiops.workbench.firecloud.model.BillingProjectMembership, BillingProjectMembership>() {
        @Override
        public BillingProjectMembership apply(
            org.pmiops.workbench.firecloud.model.BillingProjectMembership billingProjectMembership) {
          BillingProjectMembership result = new BillingProjectMembership();
          result.setProjectName(billingProjectMembership.getProjectName());
          result.setRole(billingProjectMembership.getRole());
          result.setStatus(
              fcToWorkbenchBillingMap.get(billingProjectMembership.getCreationStatus()));
          return result;
        }
      };
  private static final Function<InstitutionalAffiliation,
      org.pmiops.workbench.db.model.InstitutionalAffiliation> FROM_CLIENT_INSTITUTIONAL_AFFILIATION =
      new Function<InstitutionalAffiliation, org.pmiops.workbench.db.model.InstitutionalAffiliation>() {
        @Override
        public org.pmiops.workbench.db.model.InstitutionalAffiliation apply(InstitutionalAffiliation institutionalAffiliation) {
          org.pmiops.workbench.db.model.InstitutionalAffiliation result =
              new org.pmiops.workbench.db.model.InstitutionalAffiliation();
          result.setRole(institutionalAffiliation.getRole());
          result.setInstitution(institutionalAffiliation.getInstitution());

          return result;
        }
      };

  private static final Logger log = Logger.getLogger(ProfileController.class.getName());

  private static final long MAX_BILLING_PROJECT_CREATION_ATTEMPTS = 5;

  private final ProfileService profileService;
  private final Provider<User> userProvider;
  private final Provider<UserAuthentication> userAuthenticationProvider;
  private final UserDao userDao;
  private final Clock clock;
  private final UserService userService;
  private final FireCloudService fireCloudService;
  private final DirectoryService directoryService;
  private final CloudStorageService cloudStorageService;
  private final NotebooksService notebooksService;
  private final Provider<WorkbenchConfig> workbenchConfigProvider;
  private final WorkbenchEnvironment workbenchEnvironment;
  private final Provider<MailService> mailServiceProvider;

  @Autowired
  ProfileController(ProfileService profileService, Provider<User> userProvider,
      Provider<UserAuthentication> userAuthenticationProvider,
      UserDao userDao,
      Clock clock, UserService userService, FireCloudService fireCloudService,
      DirectoryService directoryService,
      CloudStorageService cloudStorageService,
      NotebooksService notebooksService,
      Provider<WorkbenchConfig> workbenchConfigProvider,
      WorkbenchEnvironment workbenchEnvironment,
      Provider<MailService> mailServiceProvider) {
    this.profileService = profileService;
    this.userProvider = userProvider;
    this.userAuthenticationProvider = userAuthenticationProvider;
    this.userDao = userDao;
    this.clock = clock;
    this.userService = userService;
    this.fireCloudService = fireCloudService;
    this.directoryService = directoryService;
    this.cloudStorageService = cloudStorageService;
    this.notebooksService = notebooksService;
    this.workbenchConfigProvider = workbenchConfigProvider;
    this.workbenchEnvironment = workbenchEnvironment;
    this.mailServiceProvider = mailServiceProvider;
  }

  @Override
  public ResponseEntity<List<BillingProjectMembership>> getBillingProjects() {
    List<org.pmiops.workbench.firecloud.model.BillingProjectMembership> memberships =
        fireCloudService.getBillingProjectMemberships();
    return ResponseEntity.ok(memberships.stream().map(TO_CLIENT_BILLING_PROJECT_MEMBERSHIP)
        .collect(Collectors.toList()));
  }

  private String createFirecloudUserAndBillingProject(User user) {
    // If the user is already registered, their profile will get updated.
    fireCloudService.registerUser(user.getContactEmail(),
        user.getGivenName(), user.getFamilyName());
    return createFirecloudBillingProject(user);
  }

  private String createFirecloudBillingProject(User user) {
    WorkbenchConfig workbenchConfig = workbenchConfigProvider.get();
    long suffix;
    if (workbenchEnvironment.isDevelopment()) {
      // For local development, make one billing project per account based on a hash of the account
      // email, and reuse it across database resets. (Assume we won't have any collisions;
      // if we discover that somebody starts using our namespace, change it up.)
      suffix = Math.abs(user.getEmail().hashCode());
    } else {
      // In other environments, create a suffix based on the user ID from the database. We will
      // add a suffix if that billing project is already taken. (If the database is reset, we
      // should consider switching the prefix.)
      suffix = user.getUserId();
    }
    // GCP billing project names must be <= 30 characters. The per-user hash, an integer,
    // is <= 10 chars.
    String billingProjectNamePrefix = workbenchConfig.firecloud.billingProjectPrefix + suffix;
    String billingProjectName = billingProjectNamePrefix;
    int numAttempts = 0;
    while (numAttempts < MAX_BILLING_PROJECT_CREATION_ATTEMPTS) {
      try {
        fireCloudService.createAllOfUsBillingProject(billingProjectName);
        break;
      } catch (ConflictException e) {
        if (workbenchEnvironment.isDevelopment()) {
          // In local development, just re-use existing projects for the account. (We don't
          // want to create a new billing project every time the database is reset.)
          log.log(Level.WARNING, String.format("Project with name '%s' already exists; using it.",
              billingProjectName));
          break;
        } else {
          numAttempts++;
          // In cloud environments, keep trying billing project names until we find one
          // that hasn't been used before, or we hit MAX_BILLING_PROJECT_CREATION_ATTEMPTS.
          billingProjectName = billingProjectNamePrefix + "-" + numAttempts;
        }
      }
    }
    if (numAttempts == MAX_BILLING_PROJECT_CREATION_ATTEMPTS) {
      throw new ServerErrorException(String.format("Encountered %d billing project name " +
          "collisions; giving up", MAX_BILLING_PROJECT_CREATION_ATTEMPTS));
    }

    try {
      // If the user is already a member of the billing project, this will have no effect.
      fireCloudService.addUserToBillingProject(user.getEmail(), billingProjectName);
    } catch (ForbiddenException e) {
      // AofU is not the owner of the billing project. This should only happen in local
      // environments (and hopefully never, given the prefix we're using.) If it happens,
      // we may need to pick a different prefix.
      log.log(Level.SEVERE, String.format("Unable to add user to billing project %s; " +
          "consider changing billing project prefix", billingProjectName), e);
      throw new ServerErrorException("Unable to add user to billing project", e);
    }
    return billingProjectName;
  }

  private User initializeUserIfNeeded() {
    UserAuthentication userAuthentication = userAuthenticationProvider.get();
    User user = userAuthentication.getUser();
    if (userAuthentication.getUserType() == UserType.SERVICE_ACCOUNT) {
      // Service accounts don't need further initialization.
      return user;
    }

    Boolean twoFactorEnabled = Optional.ofNullable(user.getTwoFactorEnabled()).orElse(false);
    if (!twoFactorEnabled) {
      user.setTwoFactorEnabled(directoryService.getUser(user.getEmail()).getIsEnrolledIn2Sv());
      userDao.save(user);
    }

    // On first sign-in, create a FC user, billing project, and set the first sign in time.
    if (user.getFirstSignInTime() == null) {
      // TODO(calbach): After the next DB wipe, switch this null check to
      // instead use the freeTierBillingProjectStatus.
      if (user.getFreeTierBillingProjectName() == null) {
        String billingProjectName = createFirecloudUserAndBillingProject(user);
        user.setFreeTierBillingProjectName(billingProjectName);
        user.setFreeTierBillingProjectStatus(BillingProjectStatus.PENDING);
      }

      user.setFirstSignInTime(new Timestamp(clock.instant().toEpochMilli()));
      // If the user is logged in, then we know that they have followed the account creation instructions sent to
      // their initial contact email address.
      user.setEmailVerificationStatus(EmailVerificationStatus.SUBSCRIBED);
      try {
        return userDao.save(user);
      } catch (ObjectOptimisticLockingFailureException e) {
        log.log(Level.WARNING, "version conflict for user update", e);
        throw new ConflictException("Failed due to concurrent modification");
      }
    }

    // Free tier billing project setup is complete; nothing to do.
    if (BillingProjectStatus.READY.equals(user.getFreeTierBillingProjectStatus())) {
      return user;
    }

    // On subsequent sign-ins to the first, attempt to complete the setup of the FC billing project
    // and mark the Workbench's project setup as completed. FC project creation is asynchronous, so
    // first confirm whether Firecloud claims the project setup is complete.
    BillingProjectStatus status;
    try {
      status = fireCloudService.getBillingProjectMemberships().stream()
          .filter(m -> user.getFreeTierBillingProjectName().equals(m.getProjectName()))
          .map(m -> fcToWorkbenchBillingMap.get(m.getCreationStatus()))
          // Should be at most one matching billing project; though we're not asserting this.
          .findFirst()
          .orElse(BillingProjectStatus.NONE);
    } catch (WorkbenchException e) {
      log.log(Level.WARNING, "failed to retrieve billing projects, continuing", e);
      return user;
    }
    switch (status) {
      case NONE:
      case PENDING:
        log.log(Level.INFO, "free tier project is still initializing, continuing");
        return user;

      case ERROR:
        int retries = Optional.ofNullable(user.getBillingProjectRetries()).orElse(0);
        if (retries < workbenchConfigProvider.get().firecloud.billingRetryCount) {
          this.userService.setBillingRetryCount(retries + 1);
          log.log(Level.INFO, String.format(
              "Billing project %s failed to be created, retrying.", user.getFreeTierBillingProjectName()));
          try {
            fireCloudService.removeUserFromBillingProject(user.getEmail(), user.getFreeTierBillingProjectName());
          } catch (WorkbenchException e) {
            log.log(Level.INFO, "Failed to remove user from errored billing project");
          }
          String billingProjectName = createFirecloudBillingProject(user);
          return this.userService.setBillingProjectNameAndStatus(billingProjectName, BillingProjectStatus.PENDING);
        } else {
          String billingProjectName = user.getFreeTierBillingProjectName();
          log.log(Level.SEVERE, String.format(
              "free tier project %s failed to be created", billingProjectName));
          return userService.setBillingProjectNameAndStatus(billingProjectName, status);
        }
      case READY:
        break;

      default:
        log.log(Level.SEVERE, String.format("unrecognized status '%s'", status));
        return user;
    }

    // Grant the user BQ job access on the billing project so that they can run BQ queries from
    // notebooks. Granting of this role is idempotent.
    try {
      fireCloudService.grantGoogleRoleToUser(user.getFreeTierBillingProjectName(),
          FireCloudService.BIGQUERY_JOB_USER_GOOGLE_ROLE, user.getEmail());
    } catch (WorkbenchException e) {
      log.log(Level.WARNING,
          "granting BigQuery role on created free tier billing project failed", e);
      // Allow the user to continue, as most workbench functionality will still be usable.
      return user;
    }
    log.log(Level.INFO, "free tier project initialized and BigQuery role granted");

    try {
      this.notebooksService.createCluster(
          user.getFreeTierBillingProjectName(), NotebooksService.DEFAULT_CLUSTER_NAME, user.getEmail());
      log.log(Level.INFO, String.format("created cluster %s/%s",
          user.getFreeTierBillingProjectName(), NotebooksService.DEFAULT_CLUSTER_NAME));
    } catch (ConflictException e) {
      log.log(Level.INFO, String.format("Cluster %s/%s already exists",
          user.getFreeTierBillingProjectName(), NotebooksService.DEFAULT_CLUSTER_NAME));
    } catch (GatewayTimeoutException e) {
      log.log(Level.WARNING, "Socket Timeout creating cluster.");
    }
    return userService.setBillingProjectNameAndStatus(user.getFreeTierBillingProjectName(), BillingProjectStatus.READY);
  }

  private ResponseEntity<Profile> getProfileResponse(User user) {
    return ResponseEntity.ok(profileService.getProfile(user));
  }

  @Override
  public ResponseEntity<Profile> getMe() {
    // Record that the user signed in, and create the user's FireCloud user and free tier billing
    // project if they haven't been created already.
    // This means they can start using the NIH billing account in FireCloud (without access to
    // the CDR); we will probably need a job that deactivates accounts after some period of
    // not accepting the terms of use.

    User user = initializeUserIfNeeded();
    return getProfileResponse(user);
  }

  @Override
  public ResponseEntity<UsernameTakenResponse> isUsernameTaken(String username) {
    return ResponseEntity.ok(
        new UsernameTakenResponse().isTaken(directoryService.isUsernameTaken(username)));
  }

  @Override
  public ResponseEntity<ContactEmailTakenResponse> isContactEmailTaken(String contactEmail) {
    return ResponseEntity.ok(
        new ContactEmailTakenResponse().isTaken(userService.getContactEmailTaken(contactEmail)));
  }

  @Override
  public ResponseEntity<Profile> createAccount(CreateAccountRequest request) {
    verifyInvitationKey(request.getInvitationKey());
    com.google.api.services.admin.directory.model.User googleUser =
        directoryService.createUser(request.getProfile().getGivenName(),
            request.getProfile().getFamilyName(), request.getProfile().getUsername(),
            request.getProfile().getContactEmail());

    // Create a user that has no data access or FC user associated.
    // We create this account before they sign in so we can keep track of which users we have
    // created Google accounts for. This can be used subsequently to delete orphaned accounts.

    // We store this information in our own database so that:
    // 1) we can support bring-your-own account in future (when we won't be using directory service)
    // 2) we can easily generate lists of researchers for the storefront, without joining to Google

    // It's possible for the profile information to become out of sync with the user's Google
    // profile, since it can be edited in our UI as well as the Google UI,  and we're fine with
    // that; the expectation is their profile in AofU will be managed in AofU, not in Google.

    userService.createUser(request.getProfile().getGivenName(),
        request.getProfile().getFamilyName(),
        googleUser.getPrimaryEmail(), request.getProfile().getContactEmail());

    try {
      mailServiceProvider.get().sendWelcomeEmail(request.getProfile().getContactEmail(), googleUser.getPassword(), googleUser);
    } catch (MessagingException e) {
      throw new WorkbenchException(e);
    }

    // TODO(dmohs): This should be 201 Created with no body, but the UI's swagger-generated code
    // doesn't allow this. Fix.
    return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
  }

  @Override
  public ResponseEntity<Profile> submitIdVerification() {
    User user = userProvider.get();
    if (user.getRequestedIdVerification() == null || !user.getRequestedIdVerification()) {
      try {
        mailServiceProvider.get().sendIdVerificationRequestEmail(user.getEmail());
      } catch (MessagingException e) {
        throw new EmailException("Error submitting id verification", e);
      }
      user.setRequestedIdVerification(true);
      userDao.save(user);
    }

    return getProfileResponse(user);
  }

  @Override
  public ResponseEntity<Profile> submitDemographicsSurvey() {
    User user = userService.submitDemographicSurvey();
    return getProfileResponse(user);
  }

  @Override
  public ResponseEntity<Profile> completeEthicsTraining() {
    User user = userService.submitEthicsTraining();
    return getProfileResponse(user);
  }

  @Override
  public ResponseEntity<Profile> submitTermsOfService() {
    User user = userService.submitTermsOfService();
    return getProfileResponse(user);
  }

  @Override
  public ResponseEntity<Void> invitationKeyVerification(InvitationVerificationRequest invitationVerificationRequest) {
    verifyInvitationKey(invitationVerificationRequest.getInvitationKey());
    return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
  }

  private void verifyInvitationKey(String invitationKey) {
    if (invitationKey == null || invitationKey.equals("") || !invitationKey.equals(cloudStorageService.readInvitationKey())) {
      throw new BadRequestException(
          "Missing or incorrect invitationKey (this API is not yet publicly launched)");
    }
  }

  /*
   * This un-authed API method is limited such that we only allow contact email updates before the user has signed in
   * with the newly created gsuite account. Once the user has logged in, they can change their contact email through
   * the normal profile update process.
   */
  @Override
  public ResponseEntity<Void> updateContactEmail(UpdateContactEmailRequest updateContactEmailRequest) {
    String username = updateContactEmailRequest.getUsername();
    com.google.api.services.admin.directory.model.User googleUser =
      directoryService.getUser(username);
    User user = userDao.findUserByEmail(username);
    String newEmail = updateContactEmailRequest.getContactEmail();
    if (!userNeverLoggedIn(googleUser, user)) {
      return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
    }
    try {
      new InternetAddress(newEmail).validate();
    } catch (AddressException e) {
      log.log(Level.INFO, "Invalid email entered.");
      return ResponseEntity.badRequest().build();
    }
    user.setContactEmail(newEmail);
    return resetPasswordAndSendWelcomeEmail(username, user);
  }

  @Override
  public ResponseEntity<Void> resendWelcomeEmail(ResendWelcomeEmailRequest resendRequest) {
    String username = resendRequest.getUsername();
    com.google.api.services.admin.directory.model.User googleUser =
      directoryService.getUser(username);
    User user = userDao.findUserByEmail(username);
    if (!userNeverLoggedIn(googleUser, user)) {
      return ResponseEntity.status(HttpStatus.FORBIDDEN).build();
    }
    return resetPasswordAndSendWelcomeEmail(username, user);
  }

  private boolean userNeverLoggedIn(com.google.api.services.admin.directory.model.User googleUser, User user) {
    return user.getFirstSignInTime() == null && googleUser.getChangePasswordAtNextLogin();
  }

  private ResponseEntity<Void> resetPasswordAndSendWelcomeEmail(String username, User user) {
    com.google.api.services.admin.directory.model.User googleUser = directoryService.resetUserPassword(username);
    try {
      mailServiceProvider.get().sendWelcomeEmail(user.getContactEmail(), googleUser.getPassword(), googleUser);
    } catch (MessagingException e) {
      return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
    }
    return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
  }

  @Override
  public ResponseEntity<Void> updateProfile(Profile updatedProfile) {
    User user = userProvider.get();
    user.setGivenName(updatedProfile.getGivenName());
    user.setFamilyName(updatedProfile.getFamilyName());
    user.setAboutYou(updatedProfile.getAboutYou());
    user.setAreaOfResearch(updatedProfile.getAreaOfResearch());

    if (updatedProfile.getContactEmail() != null &&
        !updatedProfile.getContactEmail().equals(user.getContactEmail())) {
      user.setContactEmail(updatedProfile.getContactEmail());
    }
    List<org.pmiops.workbench.db.model.InstitutionalAffiliation> newAffiliations =
        updatedProfile.getInstitutionalAffiliations()
            .stream().map(FROM_CLIENT_INSTITUTIONAL_AFFILIATION)
            .collect(Collectors.toList());
    int i = 0;
    ListIterator<org.pmiops.workbench.db.model.InstitutionalAffiliation> oldAffilations =
        user.getInstitutionalAffiliations().listIterator();
    boolean shouldAdd = false;
    if (newAffiliations.size() == 0) {
      shouldAdd = true;
    }
    Long userId = user.getUserId();
    for (org.pmiops.workbench.db.model.InstitutionalAffiliation affiliation : newAffiliations) {
      affiliation.setOrderIndex(i);
      affiliation.setUserId(userId);
      if (oldAffilations.hasNext()) {
        org.pmiops.workbench.db.model.InstitutionalAffiliation oldAffilation = oldAffilations.next();
        if (!oldAffilation.getRole().equals(affiliation.getRole())
            || !oldAffilation.getInstitution().equals(affiliation.getInstitution())) {
          shouldAdd = true;
        }
      } else {
        shouldAdd = true;
      }
      i++;
    }
    if (oldAffilations.hasNext()) {
      shouldAdd = true;
    }
    if (shouldAdd) {
      user.clearInstitutionalAffiliations();
      for (org.pmiops.workbench.db.model.InstitutionalAffiliation affiliation : newAffiliations) {
        user.addInstitutionalAffiliation(affiliation);
      }
    }


    // This does not update the name in Google.
    userDao.save(user);
    return ResponseEntity.status(HttpStatus.NO_CONTENT).build();
  }

  @Override
  @AuthorityRequired({Authority.REVIEW_ID_VERIFICATION})
  public ResponseEntity<IdVerificationListResponse> getIdVerificationsForReview() {
    IdVerificationListResponse response = new IdVerificationListResponse();
    List<Profile> responseList = new ArrayList<>();
    for (User user : userService.getNonVerifiedUsers()) {
      responseList.add(profileService.getProfile(user));
    }
    response.setProfileList(responseList);
    return ResponseEntity.ok(response);
  }

  @Override
  @AuthorityRequired({Authority.REVIEW_ID_VERIFICATION})
  public ResponseEntity<IdVerificationListResponse> reviewIdVerification(Long userId, IdVerificationReviewRequest review) {
    IdVerificationStatus status = review.getNewStatus();
    Boolean oldVerification = userDao.findUserByUserId(userId).getIdVerificationIsValid();
    String newValue;

    if (status == IdVerificationStatus.VERIFIED) {
      userService.setIdVerificationApproved(userId, true);
      newValue = "true";
    } else {
      userService.setIdVerificationApproved(userId, false);
      newValue = "false";
    }

    userService.logAdminUserAction(
        userId,
        "manual ID verification",
        oldVerification,
        newValue
    );
    return getIdVerificationsForReview();
  }
}
