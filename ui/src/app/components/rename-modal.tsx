import {
  Button
} from 'app/components/buttons';
import {styles as headerStyles} from 'app/components/headers';
import {TextInput, ValidationError} from 'app/components/inputs';
import {
  Modal,
  ModalBody,
  ModalFooter,
  ModalTitle,
} from 'app/components/modals';
import {TooltipTrigger} from 'app/components/popups';
import colors from 'app/styles/colors';
import {reactStyles, summarizeErrors} from 'app/utils';
import * as React from 'react';
import {validate} from 'validate.js';

const styles = reactStyles({
  fieldHeader: {
    fontSize: 14,
    color: colors.primary,
    fontWeight: 600,
    display: 'block'
  }
});

interface Props {
  hideDescription?: boolean;
  existingNames?: string[];
  oldDescription?: string;
  oldName: string;
  onCancel: Function;
  onRename: Function;
  nameFormat?: Function;
  type: string;
}

interface States {
  newName: string;
  nameTouched: boolean;
  resourceDescription: string;
  saving: boolean;
}
export class RenameModal extends React.Component<Props, States> {
  constructor(props) {
    super(props);
    this.state = {
      newName: '',
      nameTouched: false,
      resourceDescription: this.props.oldDescription,
      saving: false
    };
  }

  onRename() {
    this.setState({saving: true});
    this.props.onRename(this.state.newName, this.state.resourceDescription);
  }

  render() {
    const {hideDescription, existingNames, oldName, type} = this.props;
    let {newName, nameTouched, resourceDescription, saving} = this.state;
    if (this.props.nameFormat) {
      newName = this.props.nameFormat(newName);
    }
    const errors = validate({newName: newName}, {newName: {
      presence: {allowEmpty: false},
      format: {
        pattern: /^[^\/]*$/,
        message: 'can\'t contain a slash'
      },
      exclusion: {
        within: existingNames,
        message: 'already exists'
      }
    }});
    return <Modal loading={saving}>
      <ModalTitle>Enter new name for {oldName}</ModalTitle>
      <ModalBody>
         <div style={headerStyles.formLabel}>New Name:</div>
        <TextInput autoFocus id='new-name'
          onChange={v => this.setState({newName: v, nameTouched: true})}/>
        <ValidationError>
          {summarizeErrors(nameTouched && errors && errors.newName)}
        </ValidationError>
        {!hideDescription && <div style={{marginTop: '1rem'}}>
          <label data-test-id='descriptionLabel' style={styles.fieldHeader}>Description: </label>
          <textarea value={resourceDescription || ' '}
                    onChange={(e) => this.setState({resourceDescription: e.target.value})}/>
        </div> }
      </ModalBody>
      <ModalFooter>
        <Button type='secondary' onClick={() => this.props.onCancel()}>Cancel</Button>
        <TooltipTrigger content={summarizeErrors(errors)}>
          <Button data-test-id='rename-button' disabled={!!errors || saving}
            style={{marginLeft: '0.5rem'}} onClick={() => this.onRename()}>
            Rename {type}
          </Button>
        </TooltipTrigger>
      </ModalFooter>
    </Modal>;
  }
}
