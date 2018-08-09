package org.pmiops.workbench.db.service;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.pmiops.workbench.db.dao.CohortDao;
import org.pmiops.workbench.db.dao.UserRecentResourceDao;
import org.pmiops.workbench.db.dao.UserRecentResourceServiceImpl;
import org.pmiops.workbench.db.dao.UserDao;
import org.pmiops.workbench.db.dao.WorkspaceDao;
import org.pmiops.workbench.db.model.Cohort;
import org.pmiops.workbench.db.model.UserRecentResource;
import org.pmiops.workbench.db.model.User;
import org.pmiops.workbench.db.model.Workspace;
import org.pmiops.workbench.test.FakeClock;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.autoconfigure.liquibase.LiquibaseAutoConfiguration;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.orm.jpa.DataJpaTest;
import org.springframework.context.annotation.Import;
import org.springframework.test.annotation.DirtiesContext;
import org.springframework.test.context.junit4.SpringRunner;

import java.sql.Timestamp;
import java.time.Instant;

@RunWith(SpringRunner.class)
@DataJpaTest
@Import(LiquibaseAutoConfiguration.class)
@AutoConfigureTestDatabase(replace = AutoConfigureTestDatabase.Replace.NONE)
@DirtiesContext(classMode = DirtiesContext.ClassMode.BEFORE_EACH_TEST_METHOD)
public class UserRecentResourceServiceTest {

  UserRecentResourceServiceImpl userRecentResourceService;

  @Autowired
  UserDao userDao;
  @Autowired
  WorkspaceDao workspaceDao;
  @Autowired
  CohortDao cohortDao;
  @Autowired
  UserRecentResourceDao notebookCohortCacheDao;

  private User newUser = new User();
  private Workspace newWorkspace = new Workspace();
  private Long cohortId;
  private long workspaceId = 1l;
  private long userId = 1l;
  private FakeClock clock;
  private static final Instant NOW = Instant.now();

  @Before
  public void setUp() {
    newUser.setUserId(userId);
    userDao.save(newUser);
    newWorkspace.setWorkspaceId(workspaceId);
    workspaceDao.save(newWorkspace);
    Cohort cohort = new Cohort();
    cohort.setWorkspaceId(workspaceId);
    cohortId = cohortDao.save(cohort).getCohortId();
    userRecentResourceService = new UserRecentResourceServiceImpl();
    userRecentResourceService.setDao(notebookCohortCacheDao);
    clock = new FakeClock(NOW);
  }

  @Test
  public void testInsertCohortEntry() {
    userRecentResourceService.updateCohortEntry(workspaceId, userId, cohortId, new Timestamp(clock.millis()));
    long rowsCount = userRecentResourceService.getDao().count();
    assertEquals(rowsCount, 1);
    Cohort cohort = new Cohort();
    cohort.setWorkspaceId(workspaceId);
    cohortId = cohortDao.save(cohort).getCohortId();
    userRecentResourceService.updateCohortEntry(workspaceId, userId, cohortId, new Timestamp(clock.millis()));
    rowsCount = userRecentResourceService.getDao().count();
    assertEquals(rowsCount, 2);
  }

  @Test
  public void testInsertNotebookEntry() {
    userRecentResourceService.updateNotebookEntry(workspaceId, userId, "notebook1", new Timestamp(clock.millis()));
    long rowsCount = userRecentResourceService.getDao().count();
    assertEquals(rowsCount, 1);
    userRecentResourceService.updateNotebookEntry(workspaceId, userId, "notebook2", new Timestamp(clock.millis()));
    rowsCount = userRecentResourceService.getDao().count();
    assertEquals(rowsCount, 2);

  }

  @Test
  public void testUpdateCohortAccessTime() {
    userRecentResourceService.updateCohortEntry(workspaceId, userId, cohortId, new Timestamp(clock.millis()));
    long rowsCount = userRecentResourceService.getDao().count();
    assertEquals(rowsCount, 1);
    clock.increment(20000);
    userRecentResourceService.updateCohortEntry(workspaceId, userId, cohortId, new Timestamp(clock.millis()));
    rowsCount = userRecentResourceService.getDao().count();
    assertEquals(rowsCount, 1);
  }

  @Test
  public void testUpdateNotebookAccessTime() {

    userRecentResourceService.updateNotebookEntry(workspaceId, userId, "notebook1", new Timestamp(clock.millis()));
    long rowsCount = userRecentResourceService.getDao().count();
    assertEquals(rowsCount, 1);
    clock.increment(200);
    userRecentResourceService.updateNotebookEntry(workspaceId, userId, "notebook1", new Timestamp(clock.millis()));
    rowsCount = userRecentResourceService.getDao().count();
    assertEquals(rowsCount, 1);
  }

  @Test
  public void testUserLimit() {
    Workspace newWorkspace = new Workspace();
    newWorkspace.setWorkspaceId(2l);
    workspaceDao.save(newWorkspace);
    userRecentResourceService.updateNotebookEntry(workspaceId, userId, "notebook", new Timestamp(clock.millis()));
    clock.increment(2000);
    userRecentResourceService.updateNotebookEntry(2l, userId, "notebooks", new Timestamp(clock.millis()));
    userRecentResourceService.updateCohortEntry(workspaceId, userId, cohortId, new Timestamp(clock.millis()));
    int count = userRecentResourceService.getUserEntryCount() - 3;
    while(count-- >= 0 ){
      clock.increment(2000);
      userRecentResourceService.updateNotebookEntry(workspaceId,userId, "notebook"+count,
          new Timestamp(clock.millis()));
    }

    clock.increment(2000);
    long rowsCount = userRecentResourceService.getDao().count();
    assertEquals(rowsCount,  userRecentResourceService.getUserEntryCount());

    userRecentResourceService.updateNotebookEntry(workspaceId, userId, "notebookExtra", new Timestamp(clock.millis()));
    rowsCount = userRecentResourceService.getDao().count();
    assertEquals(rowsCount,  userRecentResourceService.getUserEntryCount());
    UserRecentResource cache = userRecentResourceService.getDao().findByUserIdAndWorkspaceIdAndNotebookName(workspaceId, userId, "notebook");
    assertNull(cache);
  }

  @Test
  public void testDeleteNotebookEntry() {
    userRecentResourceService.updateNotebookEntry(workspaceId, userId, "notebook1", new Timestamp(clock.millis()));
    long rowsCount = userRecentResourceService.getDao().count();
    assertEquals(rowsCount, 1);
    userRecentResourceService.deleteNotebookEntry(workspaceId, userId, "notebook1");
    rowsCount = userRecentResourceService.getDao().count();
    assertEquals(rowsCount, 0);
  }

  @Test
  public void testDeleteNonExistentNotebookEntry() {
    long rowsCount = userRecentResourceService.getDao().count();
    assertEquals(rowsCount, 0);
    userRecentResourceService.deleteNotebookEntry(workspaceId, userId, "notebook");
    rowsCount = userRecentResourceService.getDao().count();
    assertEquals(rowsCount, 0);
  }
}

