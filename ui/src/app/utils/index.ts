import {Router} from '@angular/router';
import {fromJS} from 'immutable';

import {DataAccessLevel} from 'generated';

export const WINDOW_REF = 'window-ref';

export function isBlank(toTest: String): boolean {
  if (toTest === null) {
    return true;
  } else {
    toTest = toTest.trim();
    return toTest === '';
  }
}

export function deepCopy(obj: Object): Object {
  return fromJS(obj).toJS();
}

/**
 * Navigate a signed out user to the login page from the given relative Angular
 * path.
 */
export function navigateLogin(router: Router, fromUrl: string): Promise<boolean> {
  const params = {};
  if (fromUrl && fromUrl !== '/') {
    params['from'] = fromUrl;
  }
  return router.navigate(['/login', params]);
}

/**
 * Determine whether the given access level is >= registered. This is the
 * minimum required level to do most things in the Workbench app (outside of
 * local/test development).
 */
export function hasRegisteredAccess(access: DataAccessLevel): boolean {
  return [
    DataAccessLevel.Registered,
    DataAccessLevel.Protected
  ].includes(access);
}
