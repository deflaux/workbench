import {currentWorkspaceStore, NavStore, urlParamsStore} from 'app/utils/navigation';
import {WorkspaceNavBarReact} from 'app/pages/workspace/workspace-nav-bar';
import {mount} from 'enzyme';
import * as React from 'react';
import {workspaceDataStub} from 'testing/stubs/workspaces-api-stub';

describe('WorkspaceNavBarComponent', () => {

  let props: {};

  const component = () => {
    return mount(<WorkspaceNavBarReact {...props}/>, {attachTo: document.getElementById('root')});
  };

  beforeEach(() => {
    props = {};

    currentWorkspaceStore.next(workspaceDataStub);
    urlParamsStore.next({ns: workspaceDataStub.namespace, wsid: workspaceDataStub.id});
  });

  it('should render', () => {
    const wrapper = component();
    expect(wrapper).toBeTruthy();
  });

  it('should highlight the active tab', () => {
    props = {tabPath: 'about'};
    const wrapper = component();
    expect(wrapper.find({'data-test-id': 'About', 'aria-selected': true}).exists()).toBeTruthy();
  });

  it('should navigate on tab click', () => {
    const navSpy = jest.fn();
    NavStore.navigate = navSpy;
    const wrapper = component();

    wrapper.find({'data-test-id': 'Data'}).first().simulate('click');
    expect(navSpy).toHaveBeenCalledWith(
      ['/workspaces', workspaceDataStub.namespace, workspaceDataStub.id, 'data']);
  });

  it('should call delete method when clicked', () => {
    const deleteSpy = jest.fn();
    props = {deleteFunction: deleteSpy};
    const wrapper = component();

    wrapper.find({'data-test-id': 'workspace-menu-button'}).first().simulate('click');
    wrapper.find({'data-test-id': 'Delete-menu-item'}).first().simulate('click');
    expect(deleteSpy).toHaveBeenCalled();
  });

  it('should call share method when clicked', () => {
    const shareSpy = jest.fn();
    props = {shareFunction: shareSpy};
    const wrapper = component();

    wrapper.find({'data-test-id': 'workspace-menu-button'}).first().simulate('click');
    wrapper.find({'data-test-id': 'Share-menu-item'}).first().simulate('click');
    expect(shareSpy).toHaveBeenCalled();
  });

});
