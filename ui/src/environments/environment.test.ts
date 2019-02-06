import {Environment} from 'environments/environment-type';
import {testEnvironmentBase} from 'environments/test-env-base';

export const environment: Environment = {
  ...testEnvironmentBase,
  displayTag: 'Test',
  debug: false,
  enableTemporal: false,
  useZendeskForSupport: true,
  enableJupyterLab: true,
  enableComplianceLockout: true
};
