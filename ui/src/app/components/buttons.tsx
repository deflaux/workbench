import {styles as cardStyles} from 'app/components/card';
import {ClrIcon} from 'app/components/icons';
import {TooltipTrigger} from 'app/components/popups';
import {IconComponent} from 'app/icons/icon';
import colors from 'app/styles/colors';
import * as fp from 'lodash/fp';
import * as React from 'react';
import * as Interactive from 'react-interactive';

export const styles = {
  base: {
    display: 'inline-flex', justifyContent: 'space-around', alignItems: 'center',
    height: '1.5rem', minWidth: '3rem', maxWidth: '15rem',
    fontWeight: 500, fontSize: 12, letterSpacing: '0.02rem', textTransform: 'uppercase',
    overflow: 'hidden', whiteSpace: 'nowrap', textOverflow: 'ellipsis',
    userSelect: 'none',
    margin: 0, padding: '0rem 0.77rem',
  },
  baseNew: {
    display: 'inline-flex', justifyContent: 'space-around', alignItems: 'center',
    minWidth: '3rem', maxWidth: '15rem',
    height: 50,
    fontWeight: 500, fontSize: 14, textTransform: 'uppercase', lineHeight: '18px',
    overflow: 'hidden', whiteSpace: 'nowrap', textOverflow: 'ellipsis',
    userSelect: 'none',
    margin: 0, padding: '0 22px',
    borderRadius: 5,
    boxSizing: 'border-box'
  }
};

const buttonVariants = {
  primary: {
    style: {
      ...styles.base,
      borderRadius: '0.3rem',
      backgroundColor: colors.purple[0], color: colors.white,
    },
    disabledStyle: {backgroundColor: colors.gray[4]},
    hover: {backgroundColor: colors.purple[1]}
  },
  secondary: {
    style: {
      ...styles.base,
      border: '1px solid', borderRadius: '0.2rem', borderColor: colors.purple[0],
      backgroundColor: 'transparent',
      color: colors.purple[0],
    },
    disabledStyle: {
      borderColor: colors.gray[4],
      backgroundColor: colors.backgroundGrey, color: colors.gray[4]
    },
    hover: {backgroundColor: colors.purple[0], color: '#ffffff'}
  },
  secondaryLight: {
    style: {
      ...styles.base,
      border: '1px solid', borderRadius: '0.2rem', borderColor: '#0077b7',
      backgroundColor: 'transparent',
      color: '#0077b7'
    },
    disabledStyle: {
      borderColor: colors.gray[4],
      backgroundColor: colors.backgroundGrey, color: colors.gray[4]
    },
    hover: {backgroundColor: colors.blue[5], color: colors.black[0]}
  },
  darklingPrimary: {
    style: {
      ...styles.base,
      borderRadius: '0.2rem',
      backgroundColor: colors.purple[0], color: colors.white
    },
    disabledStyle: {backgroundColor: colors.gray[4]},
    hover: {backgroundColor: 'rgba(255,255,255,0.3)'}
  },
  darklingSecondary: {
    style: {
      ...styles.base,
      borderRadius: '0.2rem',
      backgroundColor: '#0079b8', color: '#ffffff'
    },
    disabledStyle: {backgroundColor: colors.gray[4]},
    hover: {backgroundColor: '#50ACE1'}
  },
  purplePrimary: {
    style: {
      ...styles.baseNew,
      backgroundColor: colors.purple[0], color: colors.white,
    },
    disabledStyle: {backgroundColor: colors.gray[4]},
    hover: {backgroundColor: colors.purple[1]}
  },
  purpleSecondary: {
    style: {
      ...styles.baseNew,
      border: '1px solid', borderColor: colors.purple[0],
      backgroundColor: 'transparent',
      color: colors.purple[0],
    },
    disabledStyle: {
      borderColor: colors.gray[4],
      backgroundColor: colors.backgroundGrey, color: colors.gray[4]
    },
    hover: {backgroundColor: colors.purple[1], color: '#fff', borderColor: colors.purple[1]}
  },
  link: {
    style: {
      color: colors.blue[0]
    },
    disabledStyle: {
      color: colors.gray[2]
    }
  }
};

const computeStyle = ({style = {}, hover = {}, disabledStyle = {}}, {disabled}) => {
  return {
    style: {...style, ...(disabled ? {cursor: 'not-allowed', ...disabledStyle} : {})},
    hover: disabled ? undefined : hover
  };
};

export const Clickable = ({as = 'div', disabled = false, onClick = null, ...props}) => {
  return <Interactive
    as={as} {...props}
    onClick={(...args) => onClick && !disabled && onClick(...args)}
  />;
};

export const Button = ({type = 'primary', style = {}, disabled = false, ...props}) => {
  return <Clickable
    disabled={disabled} {...props}
    {...fp.merge(computeStyle(buttonVariants[type], {disabled}), {style})}
  />;
};

export const MenuItem = ({icon, tooltip = '', disabled = false, children, ...props}) => {
  return <TooltipTrigger side='left' content={tooltip}>
    <Clickable
      data-test-id={icon}
      disabled={disabled}
      style={{
        display: 'flex', alignItems: 'center', justifyContent: 'start',
        fontSize: 12, minWidth: 125, height: 32,
        color: disabled ? colors.gray[2] : 'black',
        padding: '0 12px',
        cursor: disabled ? 'not-allowed' : 'pointer'
      }}
      hover={!disabled ? {backgroundColor: colors.blue[4]} : undefined}
      {...props}
    >
      <ClrIcon shape={icon} style={{marginRight: 8}} size={15}/>
      {children}
    </Clickable>
  </TooltipTrigger>;
};

export const IconButton = ({icon, style = {}, tooltip = '', disabled = false, ...props}) => {
  return <TooltipTrigger side='left' content={tooltip}>
    <Clickable
        data-test-id={icon}
        disabled={disabled}
        {...props}
    >
      <IconComponent icon={icon} disabled={disabled} style={style}/>
    </Clickable>
  </TooltipTrigger>;
};

const cardButtonBase = {
  style: {
    alignItems: 'flex-start', alignContent: 'left', fontWeight: 500,
    justifyContent: 'center', padding: '0 1rem', color: colors.blue[0],
  },
  disabledStyle: {color: '#c3c3c3', backgroundColor: '#f1f2f2', cursor: 'not-allowed'}

};

const cardButtonStyle = {
  large: {
    style: {
      ...cardStyles.workspaceCard, ...cardButtonBase.style,
      boxShadow: '0 0 2px 0 rgba(0, 0, 0, 0.12), 0 3px 2px 0 rgba(0, 0, 0, 0.12)',
      fontSize: 20, lineHeight: '28px',
    },
    disabledStyle: {...cardButtonBase.disabledStyle}
  },

  small: {
    style : {
      ...cardStyles.resourceCard, ...cardButtonBase.style,
      fontSize: 18, lineHeight: '22px',
      minWidth: '200px', maxWidth: '200px', minHeight: '105px', maxHeight: '105px',
      marginTop: '1rem', marginRight: '1rem',
    },
    disabledStyle: {...cardButtonBase.disabledStyle}
  }
};

export const CardButton = ({type = 'large', disabled = false, style = {}, children, ...props}) => {
  return <Clickable
    disabled={disabled} {...props}
    {...fp.merge(computeStyle(cardButtonStyle[type], {disabled}), {style})}
  >{children}</Clickable>;
};

const tabButtonStyle = {
  style: {
    margin: '0 1rem',
    textAlign: 'center',
    color: '#2691D0',
    fontSize: '16px',
    lineHeight: '28px',
  },
  hover: {},
  disabledStyle: {}
};

const activeTabButtonStyle = {
  style: {
    borderBottom: '4px solid #216FB4',
    fontWeight: 600
  }
};

export const TabButton = ({disabled = false, style = {}, active = false, children, ...props}) => {
  const tabButtonStyleMerged = {
    style: {...tabButtonStyle.style, ...(active ? activeTabButtonStyle.style : {})},
    hover: tabButtonStyle.hover,
    disabledStyle: tabButtonStyle.disabledStyle,
  };
  return <Clickable
    disabled={disabled} {...props}
    {...fp.merge(computeStyle(tabButtonStyleMerged, {disabled}), {style})}
  >{children}</Clickable>;
};

export const Link = ({disabled = false, style = {}, children, ...props}) => {
  const linkStyle = {
    style: {color: '#2691D0'},
    hover: {textDecoration: 'underline'}
  };
  return <Clickable
      disabled={disabled} {...props}
      {...fp.merge(computeStyle(linkStyle, {disabled}), {style})}
  >{children}</Clickable>;
};
