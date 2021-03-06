package org.pmiops.workbench.notebooks;

import com.google.cloud.storage.Blob;
import com.google.cloud.storage.BlobId;
import java.nio.charset.StandardCharsets;
import java.sql.Timestamp;
import java.time.Clock;
import java.util.Collections;
import java.util.List;
import java.util.stream.Collectors;
import javax.inject.Provider;
import org.json.JSONObject;
import org.owasp.html.HtmlPolicyBuilder;
import org.owasp.html.PolicyFactory;
import org.owasp.html.Sanitizers;
import org.pmiops.workbench.db.dao.UserRecentResourceService;
import org.pmiops.workbench.db.model.User;
import org.pmiops.workbench.firecloud.FireCloudService;
import org.pmiops.workbench.google.CloudStorageService;
import org.pmiops.workbench.google.GoogleCloudLocators;
import org.pmiops.workbench.model.FileDetail;
import org.pmiops.workbench.model.WorkspaceAccessLevel;
import org.pmiops.workbench.workspaces.WorkspaceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

@Service
public class NotebooksServiceImpl implements NotebooksService {

  private static final PolicyFactory PREVIEW_SANITIZER =
      Sanitizers.FORMATTING
          .and(Sanitizers.BLOCKS)
          .and(Sanitizers.LINKS)
          .and(Sanitizers.STYLES)
          .and(Sanitizers.TABLES)
          .and(
              new HtmlPolicyBuilder()
                  // nbconvert renders styles into a style tag; unfortunately the OWASP library does
                  // not provide a good way of sanitizing this. This may render our iframe
                  // vulnerable to injection if vulnerabilities in nbconvert allow for custom style
                  // tag injection.
                  .allowTextIn("style")
                  // <pre> is not included in the prebuilt sanitizers; it is used for monospace code
                  // block formatting
                  .allowElements("style", "pre")
                  // Allow id/class in order to interact with the style tag.
                  .allowAttributes("id", "class")
                  .globally()
                  .toFactory());

  private final Clock clock;
  private final CloudStorageService cloudStorageService;
  private final FireCloudService fireCloudService;
  private final Provider<User> userProvider;
  private final UserRecentResourceService userRecentResourceService;
  private final WorkspaceService workspaceService;

  @Autowired
  public NotebooksServiceImpl(
      Clock clock,
      CloudStorageService cloudStorageService,
      FireCloudService fireCloudService,
      Provider<User> userProvider,
      UserRecentResourceService userRecentResourceService,
      WorkspaceService workspaceService) {
    this.clock = clock;
    this.cloudStorageService = cloudStorageService;
    this.fireCloudService = fireCloudService;
    this.userProvider = userProvider;
    this.userRecentResourceService = userRecentResourceService;
    this.workspaceService = workspaceService;
  }

  @Override
  public List<FileDetail> getNotebooks(String workspaceNamespace, String workspaceName) {
    String bucketName =
        fireCloudService
            .getWorkspace(workspaceNamespace, workspaceName)
            .getWorkspace()
            .getBucketName();

    return cloudStorageService.getBlobList(bucketName, NOTEBOOKS_WORKSPACE_DIRECTORY).stream()
        .filter(blob -> NOTEBOOK_PATTERN.matcher(blob.getName()).matches())
        .map(blob -> blobToFileDetail(blob, bucketName))
        .collect(Collectors.toList());
  }

  private FileDetail blobToFileDetail(Blob blob, String bucketName) {
    String[] parts = blob.getName().split("/");
    FileDetail fileDetail = new FileDetail();
    fileDetail.setName(parts[parts.length - 1]);
    fileDetail.setPath("gs://" + bucketName + "/" + blob.getName());
    fileDetail.setLastModifiedTime(blob.getUpdateTime());
    return fileDetail;
  }

  @Override
  public FileDetail copyNotebook(
      String fromWorkspaceNamespace,
      String fromWorkspaceName,
      String fromNotebookName,
      String toWorkspaceNamespace,
      String toWorkspaceName,
      String newNotebookName) {
    newNotebookName = NotebooksService.withNotebookExtension(newNotebookName);
    GoogleCloudLocators fromNotebookLocators =
        getNotebookLocators(fromWorkspaceNamespace, fromWorkspaceName, fromNotebookName);
    GoogleCloudLocators newNotebookLocators =
        getNotebookLocators(toWorkspaceNamespace, toWorkspaceName, newNotebookName);

    workspaceService.enforceWorkspaceAccessLevel(
        fromWorkspaceNamespace, fromWorkspaceName, WorkspaceAccessLevel.READER);
    workspaceService.enforceWorkspaceAccessLevel(
        toWorkspaceNamespace, toWorkspaceName, WorkspaceAccessLevel.WRITER);
    if (!cloudStorageService
        .blobsExist(Collections.singletonList(newNotebookLocators.blobId))
        .isEmpty()) {
      throw new BlobAlreadyExistsException();
    }
    cloudStorageService.copyBlob(fromNotebookLocators.blobId, newNotebookLocators.blobId);

    FileDetail fileDetail = new FileDetail();
    fileDetail.setName(newNotebookName);
    fileDetail.setPath(newNotebookLocators.fullPath);
    Timestamp now = new Timestamp(clock.instant().toEpochMilli());
    fileDetail.setLastModifiedTime(now.getTime());
    userRecentResourceService.updateNotebookEntry(
        workspaceService.getRequired(toWorkspaceNamespace, toWorkspaceName).getWorkspaceId(),
        userProvider.get().getUserId(),
        newNotebookLocators.fullPath,
        now);

    return fileDetail;
  }

  @Override
  public FileDetail cloneNotebook(
      String workspaceNamespace, String workspaceName, String fromNotebookName) {
    String newName = "Duplicate of " + fromNotebookName;
    return copyNotebook(
        workspaceNamespace,
        workspaceName,
        fromNotebookName,
        workspaceNamespace,
        workspaceName,
        newName);
  }

  @Override
  public void deleteNotebook(String workspaceNamespace, String workspaceName, String notebookName) {
    GoogleCloudLocators notebookLocators =
        getNotebookLocators(workspaceNamespace, workspaceName, notebookName);
    cloudStorageService.deleteBlob(notebookLocators.blobId);
    userRecentResourceService.deleteNotebookEntry(
        workspaceService.getRequired(workspaceNamespace, workspaceName).getWorkspaceId(),
        userProvider.get().getUserId(),
        notebookLocators.fullPath);
  }

  @Override
  public FileDetail renameNotebook(
      String workspaceNamespace, String workspaceName, String originalName, String newName) {
    FileDetail fileDetail =
        copyNotebook(
            workspaceNamespace,
            workspaceName,
            originalName,
            workspaceNamespace,
            workspaceName,
            NotebooksService.withNotebookExtension(newName));
    deleteNotebook(workspaceNamespace, workspaceName, originalName);

    return fileDetail;
  }

  @Override
  public JSONObject getNotebookContents(String bucketName, String notebookName) {
    return cloudStorageService.getFileAsJson(
        bucketName, "notebooks/".concat(NotebooksService.withNotebookExtension(notebookName)));
  }

  @Override
  public void saveNotebook(String bucketName, String notebookName, JSONObject notebookContents) {
    cloudStorageService.writeFile(
        bucketName,
        "notebooks/" + NotebooksService.withNotebookExtension(notebookName),
        notebookContents.toString().getBytes(StandardCharsets.UTF_8));
  }

  @Override
  public String getReadOnlyHtml(
      String workspaceNamespace, String workspaceName, String notebookName) {
    String bucketName =
        fireCloudService
            .getWorkspace(workspaceNamespace, workspaceName)
            .getWorkspace()
            .getBucketName();

    // We need to send a byte array so the ApiClient attaches the body as is instead
    // of serializing it through Gson which it will do for Strings.
    // The default Gson serializer does not work since it strips out some null fields
    // which are needed for nbconvert
    byte[] contents = getNotebookContents(bucketName, notebookName).toString().getBytes();
    return PREVIEW_SANITIZER.sanitize(fireCloudService.staticNotebooksConvert(contents));
  }

  private GoogleCloudLocators getNotebookLocators(
      String workspaceNamespace, String workspaceName, String notebookName) {
    String bucket =
        fireCloudService
            .getWorkspace(workspaceNamespace, workspaceName)
            .getWorkspace()
            .getBucketName();
    String blobPath = NOTEBOOKS_WORKSPACE_DIRECTORY + "/" + notebookName;
    String pathStart = "gs://" + bucket + "/";
    String fullPath = pathStart + blobPath;
    BlobId blobId = BlobId.of(bucket, blobPath);
    return new GoogleCloudLocators(blobId, fullPath);
  }
}
