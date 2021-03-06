import * as React from 'react';

import colors, {colorWithWhiteness} from 'app/styles/colors';

export interface PlaygroundModeIconProps {
  disabled: boolean;
  style: React.CSSProperties;
  enableHoverEffect: boolean;
}

export interface PlaygroundModeIconState {
  style: React.CSSProperties;
}

const defaultStyle = {
  height: 19,
  width: 19,
  marginLeft: '.5rem',
  fill: colors.accent,
  cursor: 'pointer'
};

const hoverStyle = {...defaultStyle, fill: colorWithWhiteness(colors.accent, 0.2)};

const disabledStyle = {cursor: 'not-allowed',
  fill: colorWithWhiteness(colors.dark, 0.6)};


export class PlaygroundModeIcon extends
  React.Component<PlaygroundModeIconProps, PlaygroundModeIconState> {
  constructor(props: PlaygroundModeIconProps) {
    super(props);
    this.state = {
      style: {...defaultStyle, ...this.props.style}
    };
  }

  mouseOver(): void {
    if (this.props.enableHoverEffect) {
      this.setState({style: {...hoverStyle, ...this.props.style}});
    }
  }

  mouseLeave(): void {
    if (this.props.enableHoverEffect) {
      this.setState({style: {...defaultStyle, ...this.props.style}});
    }
  }

  render() {
    return <svg style={this.props.disabled ? {...this.state.style,
      ...disabledStyle} : this.state.style}
      version='1.1'
      id='Layer_1'
      viewBox='0 0 14.1 12.3'
      onMouseOver={() => this.mouseOver()}
      onMouseLeave={() => this.mouseLeave()}>
      <title>Group</title>
      <desc>Created with Sketch.</desc>
      <g id='ANAYLSIS'>
        <g id='Notebook-PREVIEW' transform='translate(-363.000000, -85.000000)'>
          <g id='Group-5' transform='translate(363.000000, 85.000000)'>
            <g id='Group-3' transform='translate(0.889808, 0.297292)'>
              <g id='Group' transform='translate(0.047675, 0.625027)'>
                <path d={
                  `M11.8-0.9c0.7,0,1.3,0.6,1.3,1.3V10c0,0.7-0.6,1.3-1.3,1.3H0.4c
            -0.7,0-1.3-0.6-1.3-1.3V0.4c0-0.7,0.6-1.3,1.3-1.3C0.4-0.9,11.8-0.9,11.8-0.9z`
                }/>
              </g>
            </g>
          </g>
        </g>
      </g>
      <path fill='#FFFFFF' d={`M3.5,3.2H2.1C2,3.2,1.9,3.1,1.9,3V1.7c0-0.1,0.1-0.2,0.2-0.2h1.5c0.1,0,
  0.2,0.1,0.2,0.2V3C3.7,3.1,3.6,3.2,3.5,3.2z`}/>
      <path fill='#FFFFFF' d={`M12.4,3.2h-7C5.3,3.2,5.2,3.1,5.2,3V1.7c0-0.1,0.1-0.2,0.2-0.2h7c0.1,0,
  0.2,0.1,0.2,0.2V3C12.6,3.1,12.5,3.2,12.4,3.2z`}/>
      <g>
        <path fill='#FFFFFF' d={`M10.8,4.6l0.5,0.5c0.1,0.1,0.1,0.2,0,0.3l-5.4,5.4c-0.1,0.1-0.2,
    0.1-0.3,0L3.2,8.4c-0.1-0.1-0.1-0.2,0-0.3l0.5-0.5c0.1-0.1,0.2-0.1,0.3,0l1.7,1.7l4.8-4.8C10.6,
    4.5,10.8,4.5,10.8,4.6z`}/>
      </g>
    </svg>;
  }
}
