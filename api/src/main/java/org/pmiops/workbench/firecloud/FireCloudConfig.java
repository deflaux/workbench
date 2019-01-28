package org.pmiops.workbench.firecloud;

import com.google.common.collect.ImmutableList;
import java.io.IOException;
import java.util.List;
import org.pmiops.workbench.auth.ServiceAccounts;
import org.pmiops.workbench.auth.UserAuthentication;
import org.pmiops.workbench.config.WorkbenchConfig;
import org.pmiops.workbench.config.WorkbenchEnvironment;
import org.pmiops.workbench.exceptions.ServerErrorException;
import org.pmiops.workbench.firecloud.api.BillingApi;
import org.pmiops.workbench.firecloud.api.GroupsApi;
import org.pmiops.workbench.firecloud.api.NihApi;
import org.pmiops.workbench.firecloud.api.ProfileApi;
import org.pmiops.workbench.firecloud.api.StatusApi;
import org.pmiops.workbench.firecloud.api.WorkspacesApi;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ScopedProxyMode;
import org.springframework.web.context.annotation.RequestScope;

@org.springframework.context.annotation.Configuration
public class FireCloudConfig {

  private static final String END_USER_API_CLIENT = "endUserApiClient";
  private static final String ALL_OF_US_API_CLIENT = "allOfUsApiClient";
  private static final String X_APP_ID_HEADER = "X-App-ID";
  private static final String X_APP_ID_HEADER_VALUE = "AoU-RW";

  public static final String END_USER_GROUPS_API = "endUserGroupsApi";
  public static final String ALL_OF_US_GROUPS_API = "allOfUsGroupsApi";

  private static final List<String> BILLING_SCOPES = ImmutableList.of(
      "https://www.googleapis.com/auth/userinfo.profile",
      "https://www.googleapis.com/auth/userinfo.email",
      "https://www.googleapis.com/auth/cloud-billing");

  @Bean(name=END_USER_API_CLIENT)
  @RequestScope(proxyMode = ScopedProxyMode.DEFAULT)
  public ApiClient fireCloudApiClient(UserAuthentication userAuthentication,
      WorkbenchConfig workbenchConfig) {
    ApiClient apiClient = new ApiClient();
    apiClient.setBasePath(workbenchConfig.firecloud.baseUrl);
    apiClient.setAccessToken(userAuthentication.getCredentials());
    apiClient.setDebugging(workbenchConfig.firecloud.debugEndpoints);
    addFireCloudDefaultHeader(apiClient);
    return apiClient;
  }

  @Bean(name=ALL_OF_US_API_CLIENT)
  @RequestScope(proxyMode = ScopedProxyMode.DEFAULT)
  public ApiClient allOfUsApiClient(WorkbenchEnvironment workbenchEnvironment,
      WorkbenchConfig workbenchConfig) {
    ApiClient apiClient = new ApiClient();
    apiClient.setBasePath(workbenchConfig.firecloud.baseUrl);
    try {
      apiClient.setAccessToken(
          ServiceAccounts.workbenchAccessToken(workbenchEnvironment, BILLING_SCOPES));
      apiClient.setDebugging(workbenchConfig.firecloud.debugEndpoints);
    } catch (IOException e) {
      throw new ServerErrorException(e);
    }
    return apiClient;
  }

  @Bean
  @RequestScope(proxyMode = ScopedProxyMode.DEFAULT)
  public ProfileApi profileApi(@Qualifier(END_USER_API_CLIENT) ApiClient apiClient) {
    ProfileApi api = new ProfileApi();
    api.setApiClient(apiClient);
    return api;
  }

  @Bean
  @RequestScope(proxyMode = ScopedProxyMode.DEFAULT)
  public WorkspacesApi workspacesApi(@Qualifier(END_USER_API_CLIENT) ApiClient apiClient) {
    WorkspacesApi api = new WorkspacesApi();
    api.setApiClient(apiClient);
    return api;
  }

  @Bean
  @RequestScope(proxyMode = ScopedProxyMode.DEFAULT)
  public BillingApi billingApi(@Qualifier(ALL_OF_US_API_CLIENT) ApiClient apiClient) {
    // Billing calls are made by the AllOfUs service account, rather than using the end user's
    // credentials.
    BillingApi api = new BillingApi();
    api.setApiClient(apiClient);
    return api;
  }

  @Bean(name = ALL_OF_US_GROUPS_API)
  @RequestScope(proxyMode = ScopedProxyMode.DEFAULT)
  public GroupsApi groupsApi(@Qualifier(ALL_OF_US_API_CLIENT) ApiClient apiClient) {
    // Group/Auth Domain creation and addition are made by the AllOfUs service account
    GroupsApi api = new GroupsApi();
    api.setApiClient(apiClient);
    return api;
  }

  @Bean(name = END_USER_GROUPS_API)
  @RequestScope(proxyMode = ScopedProxyMode.DEFAULT)
  public GroupsApi groupApi(@Qualifier(END_USER_API_CLIENT) ApiClient apiClient) {
    // When checking for membership in groups, we use the end user credentials.
    GroupsApi api = new GroupsApi();
    api.setApiClient(apiClient);
    return api;
  }

  @Bean
  @RequestScope(proxyMode = ScopedProxyMode.DEFAULT)
  public NihApi nihApi(@Qualifier(END_USER_API_CLIENT) ApiClient apiClient) {
    // When checking for NIH account information, we use the end user credentials.
    return new NihApi(apiClient);
  }

  @Bean
  @RequestScope(proxyMode = ScopedProxyMode.DEFAULT)
  public StatusApi statusApi(WorkbenchConfig workbenchConfig) {
    StatusApi statusApi = new StatusApi();
    ApiClient apiClient = new ApiClient();
    apiClient.setBasePath(workbenchConfig.firecloud.baseUrl);
    apiClient.setDebugging(workbenchConfig.firecloud.debugEndpoints);
    addFireCloudDefaultHeader(apiClient);
    statusApi.setApiClient(apiClient);
    return statusApi;
  }

  private void addFireCloudDefaultHeader(ApiClient apiClient) {
    apiClient.addDefaultHeader(X_APP_ID_HEADER, X_APP_ID_HEADER_VALUE);
  }

}
