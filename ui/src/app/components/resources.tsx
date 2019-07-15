import * as React from 'react';

import {Clickable, MenuItem} from 'app/components/buttons';
import {ClrIcon} from 'app/components/icons';
import {PopupTrigger} from 'app/components/popups';
import colors, {colorWithWhiteness} from 'app/styles/colors';
import {switchCase} from 'app/utils';
import {ResourceType} from 'app/utils/resourceActionsReact';
import {environment} from 'environments/environment';

export const ResourceCardMenu: React.FunctionComponent<{
  disabled: boolean, resourceType: ResourceType, onRenameNotebook?: Function,
  onRenameCohort?: Function, onOpenJupyterLabNotebook?: any, onCloneResource?: Function,
  onCopyResource?: Function, onDeleteResource?: Function, onEdit?: Function,
  onExportDataSet: Function, onReviewCohort?: Function, onRenameDataSet?: Function
}> = ({
        disabled, resourceType, onRenameNotebook = () => {}, onRenameCohort = () => {},
        onOpenJupyterLabNotebook = () => {}, onCloneResource = () => {}, onCopyResource = () => {},
        onDeleteResource = () => {}, onEdit = () => {}, onExportDataSet = () => {},
        onReviewCohort = () => {}, onRenameDataSet = () => {}
      }) => {
  return <PopupTrigger
    data-test-id='resource-card-menu'
    side='bottom'
    closeOnClick
    content={
      switchCase(resourceType,
        ['notebook', () => {
          return <React.Fragment>
            <MenuItem onClick={onRenameNotebook}>Rename</MenuItem>
            <MenuItem onClick={onCloneResource}>Duplicate</MenuItem>
            <MenuItem onClick={onCopyResource}>Copy to another Workspace</MenuItem>
            <MenuItem onClick={onDeleteResource}>Delete</MenuItem>
            {
              environment.enableJupyterLab &&
              /*
               This does not support both playground mode and jupyterLab yet,
               that is a work in progress. We do not need to worry about that
               here, because the menu will not open if you do not have write
               access, and playground mode is currently only enabled if you do
               not have write access.
              */
              <MenuItem onClick={onOpenJupyterLabNotebook}>Open in Jupyter Lab</MenuItem>
            }
          </React.Fragment>;
        }],
        ['cohort', () => {
          return <React.Fragment>
            <MenuItem onClick={onRenameCohort}>Rename</MenuItem>
            <MenuItem onClick={onCloneResource}>Duplicate</MenuItem>
            <MenuItem onClick={onEdit}>Edit</MenuItem>
            <MenuItem onClick={onReviewCohort}>Review</MenuItem>
            <MenuItem onClick={onDeleteResource}>Delete</MenuItem>
          </React.Fragment>;
        }],
        ['conceptSet', () => {
          return <React.Fragment>
            <MenuItem onClick={onEdit}>Rename</MenuItem>
            <MenuItem onClick={onDeleteResource}>Delete</MenuItem>
          </React.Fragment>;
        }],
        ['dataSet', () => {
          return <React.Fragment>
            <MenuItem onClick={onRenameDataSet}>Rename Data Set</MenuItem>
            <MenuItem onClick={onEdit}>Edit</MenuItem>
            <MenuItem onClick={onExportDataSet}>Export to Notebook</MenuItem>
            <MenuItem onClick={onDeleteResource}>Delete</MenuItem>
          </React.Fragment>;
        }]
      )
    }
  >
    <Clickable disabled={disabled} data-test-id='resource-menu'>
      <ClrIcon shape='ellipsis-vertical' size={21}
               style={{color: disabled ? colorWithWhiteness(colors.dark, 0.6) : colors.accent,
                 marginLeft: -9, cursor: disabled ? 'auto' : 'pointer'}}/>
    </Clickable>
  </PopupTrigger>;
};
