package org.pmiops.workbench.billing;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doReturn;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.verifyZeroInteractions;

import com.google.cloud.bigquery.TableResult;
import java.io.InputStream;
import java.io.ObjectInputStream;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.pmiops.workbench.api.BigQueryService;
import org.pmiops.workbench.config.WorkbenchConfig;
import org.pmiops.workbench.db.dao.UserDao;
import org.pmiops.workbench.db.dao.WorkspaceDao;
import org.pmiops.workbench.db.model.User;
import org.pmiops.workbench.db.model.Workspace;
import org.pmiops.workbench.model.WorkspaceActiveStatus;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.liquibase.LiquibaseAutoConfiguration;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.boot.test.context.TestConfiguration;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Import;
import org.springframework.context.annotation.Scope;
import org.springframework.test.context.junit4.SpringRunner;

@RunWith(SpringRunner.class)
@DataJpaTest
@Import(LiquibaseAutoConfiguration.class)
public class BillingAlertsServiceTest {

  @Autowired BigQueryService bigQueryService;

  @Autowired BillingAlertsService billingAlertsService;

  @Autowired UserDao userDao;

  @Autowired NotificationService notificationService;

  @Autowired WorkspaceDao workspaceDao;

  private static WorkbenchConfig workbenchConfig;

  @TestConfiguration
  @Import({BillingAlertsService.class})
  @MockBean({BigQueryService.class, NotificationService.class})
  static class Configuration {
    @Bean
    @Scope("prototype")
    public WorkbenchConfig workbenchConfig() {
      return workbenchConfig;
    }
  }

  @Before
  public void setUp() throws Exception {
    workbenchConfig = WorkbenchConfig.createEmptyConfig();

    InputStream inputStream =
        getClass().getClassLoader().getResourceAsStream("bigquery/get_billing_project_costs.ser");
    TableResult tableResult = (TableResult) (new ObjectInputStream(inputStream)).readObject();

    doReturn(tableResult).when(bigQueryService).executeQuery(any());
  }

  @Test
  public void namespaceToCreator() {
    User user = createUser("test@test.com");
    createWorkspace(user, "rumney");
    createWorkspace(user, "rumney");

    assertThat(workspaceDao.namespaceToCreator().get("rumney")).isEqualTo(user);
  }

  @Test
  public void checkFreeTierBillingUsage_singleProjectExceedsLimit() {
    workbenchConfig.billing.defaultFreeCreditsLimit = 100.0;

    User user = createUser("test@test.com");
    createWorkspace(user, "aou-test-f1-26");

    billingAlertsService.checkFreeTierBillingUsage();
    verify(notificationService).alertUser(eq(user), any());
  }

  @Test
  public void checkFreeTierBillingUsage_disabledUserNotIgnored() {
    workbenchConfig.billing.defaultFreeCreditsLimit = 100.0;

    User user = createUser("test@test.com");
    user.setDisabled(true);
    userDao.save(user);
    createWorkspace(user, "aou-test-f1-26");

    billingAlertsService.checkFreeTierBillingUsage();
    verify(notificationService).alertUser(eq(user), any());
  }

  @Test
  public void checkFreeTierBillingUsage_deletedWorkspaceNotIgnored() {
    workbenchConfig.billing.defaultFreeCreditsLimit = 100.0;

    User user = createUser("test@test.com");
    Workspace workspace = createWorkspace(user, "aou-test-f1-26");
    workspace.setWorkspaceActiveStatusEnum(WorkspaceActiveStatus.DELETED);
    workspaceDao.save(workspace);

    billingAlertsService.checkFreeTierBillingUsage();
    verify(notificationService).alertUser(eq(user), any());
  }

  @Test
  public void checkFreeTierBillingUsage_noAlert() {
    workbenchConfig.billing.defaultFreeCreditsLimit = 500.0;

    User user = createUser("test@test.com");
    createWorkspace(user, "aou-test-f1-26");

    billingAlertsService.checkFreeTierBillingUsage();
    verifyZeroInteractions(notificationService);
  }

  @Test
  public void checkFreeTierBillingUsage_workspaceMissingCreator() {
    workbenchConfig.billing.defaultFreeCreditsLimit = 500.0;

    User user = createUser("test@test.com");
    createWorkspace(user, "aou-test-f1-26");
    createWorkspace(null, "rumney");

    billingAlertsService.checkFreeTierBillingUsage();
    verifyZeroInteractions(notificationService);
  }

  @Test
  public void checkFreeTierBillingUsage_combinedProjectsExceedsLimit() {
    workbenchConfig.billing.defaultFreeCreditsLimit = 500.0;

    User user = createUser("test@test.com");
    createWorkspace(user, "aou-test-f1-26");
    createWorkspace(user, "aou-test-f1-47");

    billingAlertsService.checkFreeTierBillingUsage();
    verify(notificationService).alertUser(eq(user), any());
  }

  @Test
  public void checkFreeTierBillingUsage_override() {
    workbenchConfig.billing.defaultFreeCreditsLimit = 10.0;

    User user = createUser("test@test.com");
    createWorkspace(user, "aou-test-f1-26");

    billingAlertsService.checkFreeTierBillingUsage();
    verify(notificationService).alertUser(eq(user), any());

    user.setFreeTierCreditsLimitOverride(1000.0);
    userDao.save(user);

    billingAlertsService.checkFreeTierBillingUsage();
    verifyZeroInteractions(notificationService);
  }

  private User createUser(String email) {
    User user = new User();
    user.setEmail(email);
    return userDao.save(user);
  }

  private Workspace createWorkspace(User creator, String namespace) {
    Workspace workspace = new Workspace();
    workspace.setCreator(creator);
    workspace.setWorkspaceNamespace(namespace);
    return workspaceDao.save(workspace);
  }
}
