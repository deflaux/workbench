import {DomainType} from 'generated';
import {List} from 'immutable';
import {CRITERIA_TYPES} from './constant';


export function typeDisplay(parameter): string {
  const subtype = parameter.get('subtype', '');
  const _type = parameter.get('type', '');
  if (_type.match(/^DEMO.*/i)) {
    return {
      'GEN': 'Gender',
      'RACE': 'Race/Ethnicity',
      'AGE': 'Age',
      'DEC': 'Deceased'
    }[subtype] || '';
  } else {
    return parameter.get('code', '');
  }
}

export function nameDisplay(parameter): string {
  const subtype = parameter.get('subtype', '');
  const _type = parameter.get('type', '');
  if (_type.match(/^DEMO.*/i) && subtype.match(/AGE|DEC/i)) {
    return '';
  } else {
    return stripHtml(parameter.get('name', ''));
  }
}

export function attributeDisplay(parameter): string {
  const attrs = parameter.get('attributes', '');

  const kind = `${parameter.get('type', '')}${parameter.get('subtype', '')}`;
  if (kind.match(/^DEMO.*AGE/i)) {
    const display = [];
    attrs.forEach(attr => {
      const op = {
        'BETWEEN': 'In Range',
        'EQUAL': 'Equal To',
        'GREATER_THAN': 'Greater Than',
        'LESS_THAN': 'Less Than',
        'GREATER_THAN_OR_EQUAL_TO': 'Greater Than or Equal To',
        'LESS_THAN_OR_EQUAL_TO': 'Less Than or Equal To',
      }[attr.get('operator')];
      const args = attr.get('operands', List()).join(', ');
      display.push(`${op} ${args}`);
    });
    return display.join(' ');
  } else {
    return '';
  }
}

export function typeToTitle(_type: string): string {
  switch (_type) {
    case CRITERIA_TYPES.DEMO:
      _type = 'Demographics';
      break;
    case CRITERIA_TYPES.MEAS:
      _type = 'Measurements';
      break;
    case CRITERIA_TYPES.PM:
      _type = 'Physical Measurements';
      break;
    case DomainType[DomainType.VISIT]:
      _type = 'Visit';
      break;
    case DomainType[DomainType.DRUG]:
      _type = 'Drug';
      break;
  }
  return _type;
}

export function highlightMatches(terms: Array<string>, name: string) {
  terms.forEach(term => {
    const start = name.toLowerCase().indexOf(term.toLowerCase());
    if (start > -1) {
      const end = start + term.length;
      name = name.slice(0, start)
        + '<span style="color: #659F3D;'
        + 'font-weight: bolder;'
        + 'background-color: rgba(101,159,61,0.2);'
        + 'padding: 2px 0;">'
        + name.slice(start, end) + '</span>'
        + name.slice(end);
    }
  });
  return name;
}

export function stripHtml(string: string) {
  return string.replace(/<(.|\n)*?>/g, '');
}
