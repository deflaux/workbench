package org.pmiops.workbench.tools;

import com.google.api.client.googleapis.auth.oauth2.GoogleCredential;
import com.google.common.base.Joiner;
import com.google.gson.Gson;
import com.google.gson.JsonObject;
import java.io.IOException;
import java.time.Clock;
import java.time.Duration;
import java.time.Instant;
import java.util.Arrays;
import java.util.Comparator;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collectors;
import javax.annotation.Nullable;
import org.pmiops.workbench.notebooks.ApiClient;
import org.pmiops.workbench.notebooks.ApiException;
import org.pmiops.workbench.notebooks.api.ClusterApi;
import org.pmiops.workbench.notebooks.model.Cluster;
import org.pmiops.workbench.notebooks.model.ClusterStatus;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.builder.SpringApplicationBuilder;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * ManageClusters is an operational utility for interacting with the Leonardo Notebook clusters
 * available to the application default user. This should generally be used while authorized as the
 * App Engine default service account for a given environment.
 *
 * <p>Note: If this utility later needs database access, replace @Configuration
 * with @SpringBootApplication.
 */
@Configuration
public class ManageClusters {

  private static final Logger log = Logger.getLogger(ManageClusters.class.getName());
  private static final String[] BILLING_SCOPES =
      new String[] {
        "https://www.googleapis.com/auth/userinfo.profile",
        "https://www.googleapis.com/auth/userinfo.email"
      };

  private static Set<String> commaDelimitedStringToSet(String str) {
    return Arrays.asList(str.split(",")).stream()
        .filter(s -> !s.isEmpty())
        .collect(Collectors.toSet());
  }

  private static ClusterApi newApiClient(String apiUrl) throws IOException {
    ApiClient apiClient = new ApiClient();
    apiClient.setBasePath(apiUrl);
    GoogleCredential credential =
        GoogleCredential.getApplicationDefault().createScoped(Arrays.asList(BILLING_SCOPES));
    credential.refreshToken();
    apiClient.setAccessToken(credential.getAccessToken());
    ClusterApi api = new ClusterApi();
    api.setApiClient(apiClient);
    return api;
  }

  private static String clusterId(Cluster c) {
    return c.getGoogleProject() + "/" + c.getClusterName();
  }

  private static String formatTabular(Cluster c) {
    Gson gson = new Gson();
    JsonObject labels = gson.toJsonTree(c.getLabels()).getAsJsonObject();
    String creator = "unknown";
    if (labels.has("created-by")) {
      creator = labels.get("created-by").getAsString();
    }
    ClusterStatus status = ClusterStatus.UNKNOWN;
    if (c.getStatus() != null) {
      status = c.getStatus();
    }
    return String.format(
        "%-30.30s %-50.50s %-10s %-15s", clusterId(c), creator, status, c.getCreatedDate());
  }

  private static void listClusters(String apiUrl) throws IOException, ApiException {
    AtomicInteger count = new AtomicInteger();
    newApiClient(apiUrl).listClusters(null, false).stream()
        .sorted(Comparator.comparing(c -> Instant.parse(c.getCreatedDate())))
        .forEachOrdered(
            (c) -> {
              System.out.println(formatTabular(c));
              count.getAndIncrement();
            });
    System.out.println(String.format("listed %d clusters", count.get()));
  }

  private static void deleteClusters(
      String apiUrl, @Nullable Instant oldest, Set<String> ids, boolean dryRun)
      throws IOException, ApiException {
    Set<String> remaining = new HashSet<>(ids);
    String dryMsg = dryRun ? "[DRY RUN]: would have... " : "";

    AtomicInteger deleted = new AtomicInteger();
    ClusterApi api = newApiClient(apiUrl);
    api.listClusters(null, false).stream()
        .sorted(Comparator.comparing(c -> Instant.parse(c.getCreatedDate())))
        .filter(
            (c) -> {
              Instant createdDate = Instant.parse(c.getCreatedDate());
              if (oldest != null && createdDate.isAfter(oldest)) {
                return false;
              }
              if (!ids.isEmpty() && !ids.contains(clusterId(c))) {
                return false;
              }
              return true;
            })
        .forEachOrdered(
            (c) -> {
              String cid = clusterId(c);
              if (!dryRun) {
                try {
                  api.deleteCluster(c.getGoogleProject(), c.getClusterName());
                } catch (ApiException e) {
                  log.log(Level.SEVERE, "failed to deleted cluster " + cid, e);
                  return;
                }
              }
              remaining.remove(cid);
              deleted.getAndIncrement();
              System.out.println(dryMsg + "deleted cluster: " + formatTabular(c));
            });
    if (!remaining.isEmpty()) {
      log.log(
          Level.SEVERE,
          "failed to find/delete clusters: {1}",
          new Object[] {Joiner.on(", ").join(remaining)});
    }
    System.out.println(String.format("%sdeleted %d clusters", dryMsg, deleted.get()));
  }

  @Bean
  public CommandLineRunner run() {
    return (args) -> {
      if (args.length < 1) {
        throw new IllegalArgumentException("must specify a command 'list' or 'delete'");
      }
      String cmd = args[0];
      args = Arrays.copyOfRange(args, 1, args.length);
      switch (cmd) {
        case "list":
          if (args.length > 1) {
            throw new IllegalArgumentException("Expected 1 arg. Got " + Arrays.asList(args));
          }
          listClusters(args[0]);
          return;

        case "delete":
          // User-friendly command-line parsing is done in devstart.rb, so we do only simple
          // positional argument parsing here.
          if (args.length != 4) {
            throw new IllegalArgumentException(
                "Expected 4 args (api_url, min_age, ids, dry_run). Got " + Arrays.asList(args));
          }
          String apiUrl = args[0];
          Instant oldest = null;
          if (!args[1].isEmpty()) {
            Duration age = Duration.ofDays(Long.parseLong(args[1]));
            oldest = Clock.systemUTC().instant().minus(age);
            log.info("only clusters created before " + oldest + " will be considered");
          }

          // Note: IDs are optional, this set may be empty.
          Set<String> ids = commaDelimitedStringToSet(args[2]);
          boolean dryRun = Boolean.valueOf(args[3]);
          deleteClusters(apiUrl, oldest, ids, dryRun);
          return;

        default:
          throw new IllegalArgumentException(
              String.format("unrecognized command '%s', want 'list' or 'delete'", cmd));
      }
    };
  }

  public static void main(String[] args) throws Exception {
    new SpringApplicationBuilder(ManageClusters.class).web(false).run(args);
  }
}
