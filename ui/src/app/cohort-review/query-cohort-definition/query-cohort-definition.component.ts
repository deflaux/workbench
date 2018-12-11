import {Component, Input, OnInit} from '@angular/core';
import {CohortBuilderService, TreeType} from 'generated';
import {typeToTitle} from '../../cohort-search/utils';



@Component({
  selector: 'app-query-cohort-definition',
  templateUrl: './query-cohort-definition.component.html',
  styleUrls: ['./query-cohort-definition.component.css']
})
export class QueryCohortDefinitionComponent implements OnInit {
  definition: Array<any>;
  ppiParents: any;
  values: Array<any>;
  types = ['ICD9', 'ICD10', 'CPT', 'VISIT', 'PM', 'DRUG',
    'MEAS', 'CONDITION', 'PROCEDURE', 'SNOMED' ];
  @Input() cohort: any;
  @Input() review: any;
  constructor(private api: CohortBuilderService) {}

  ngOnInit() {
    this.mapDefinition();
     console.log(JSON.parse(this.cohort.criteria));
  }

  mapDefinition() {
    const definition = JSON.parse(this.cohort.criteria);
    this.ppiCheck(definition).then(parents => {
      this.ppiParents = parents;
      // console.log(this.ppiParents);
      this.definition = ['includes', 'excludes'].map(role => {
        if (definition[role].length) {
          const roleObj = {role, groups: []};
          definition[role].forEach(group => {
            roleObj.groups.push(this.mapGroup(group));
          });
          return roleObj;
        }
      });

      console.log(this.definition);

    });

  }

  mapGroup(group: any) {
    return group.items.map(item => {
      switch (item.type) {
        case TreeType.PM:
          return this.mapPMParams(item.searchParameters, item.type);
        case TreeType.PPI:
          return this.mapPPIParams(item.searchParameters, item.type);
        default:
          return this.mapParams(item.type, item.searchParameters, item.modifiers);
      }
    });
  }

  // Physical Measurement
  mapPMParams(params: Array<any>, _type) {
    this.getValues(params, _type);
    const PMarray = params.map(param => {
      return {
        items: typeToTitle(param.type) + ' | ' + this.values,
        type: param.type
      };
    });
    return this.removeDuplicates(PMarray);
  }


  // PPI

  mapPPIParams(params: Array<any>, _type) {
    this.getValues(params, _type);
    const PpiArray = params.map(param => {
      return {
        items: typeToTitle(param.type)
          + ' | ' + this.values,
        type: param.type
      };
    });
    return this.removeDuplicates(PpiArray);
  }


  async ppiCheck(definition: any) {
    const parents = {};
    for (const role in definition) {
      if (definition.hasOwnProperty(role)) {
        for (const group of definition[role]) {
          for (const item of group.items) {
            if (item.type !== TreeType[TreeType.PPI]) {
              continue;
            }
            for (const param of item.searchParameters) {
              const name = await this.getPPIParent(param.conceptId);
              parents[param.conceptId] = name;
            }
          }
        }
      }
    }
    return new Promise(resolve => {
      resolve(parents);
    });
  }

  async getPPIParent(conceptId: string) {
    let name;
    await this.api
      .getPPICriteriaParent(this.review.cdrVersionId, TreeType[TreeType.PPI], conceptId)
      .toPromise()
      .then(parent => name = parent.name);
    return name;
  }

  // other than ppi and PM

  mapParams(_type: string, params: Array<any>, mod) {
     this.getValues(params, _type);
    if (mod.length > 0) {
      const modArray = params.map(eachParam => {
        let name;
        name = mod.reduce((acc, m) => {
          const concatOperand = m.operands.reduce((final, o) => {
            return final !== '' ? `${final} & ${o}` : `${final} ${o}`;
          } , '');
          return acc !== '' ?
            `${acc} ,  ${this.removeUnderScoreLowerCase(m.name)}
            ${this.operatorConversion(m.operator)}
            ${concatOperand}`
            :
            `${this.removeUnderScoreLowerCase(m.name)} ${this.operatorConversion(m.operator)}
            ${concatOperand}`;
        }, '');
        return {
          items: `${typeToTitle(_type)} | ${eachParam.type} | ${this.values} | ${name}`,
          type: eachParam.type
        };
      });
      return this.removeDuplicates(modArray);
    } else {
      const noModArray = params.map(param => {
        if (param.type === 'DEMO') {
          return {items: `${typeToTitle(_type)}
                      | ${param.type} | ${this.operatorConversion(param.subtype)} ${param.name}`,
            type: param.type};
        } else if (param.type === 'VISIT') {
          return {items: `${typeToTitle(_type)} | ${param.name}`,
            type: param.type};
        } else {
          return _type === 'CONDITION' || _type === 'PROCEDURE' ?
            {items: `${typeToTitle(_type)} | ${param.type} | ${this.values}`,
            type: param.type} :
            {items: `${typeToTitle(_type)} | ${this.values}`,
            type: param.type};
        }
      });
      return this.removeDuplicates(noModArray);
    }
  }

// utils
  removeDuplicates(arr) {
    return arr.filter((thing, index, self) =>
      index === self.findIndex((t) => (
        t.items === thing.items && t.type === thing.type
      ))
    );
  }

  removeUnderScoreLowerCase(name: string) {
    return name.replace(/_/g, ' ').toLowerCase();
  }

  operatorConversion(operator) {
    switch (operator) {
      case 'GREATER_THAN_OR_EQUAL_TO' :
        return '>=';
      case 'LESS_THAN_OR_EQUAL_TO' :
        return '<=';
      case 'EQUAL' :
        return '=';
      case 'BETWEEN' :
        return 'between';
      case 'ETH' :
        return 'Ethnicity';
      case 'RACE' :
        return 'Race';
      case 'AGE' :
        return 'Age';
    }
  }

  getValues(p, type) {
    this.values = p.map(m => {
      if (type === 'PM') {
        if (m.name) {
          return m.name;
        }
      } else if (type === 'PPI') {
        if (m.name) {
          return  this.ppiParents[m.conceptId] + ' | ' + m.name ;
        }
      } else {
        if (m.value && m.type !== 'SNOMED') {
          if (m.group === true) {
            return  'Parent ' + m.value;
          } else {
            return  m.value;
          }
        } else {
          return m.name;
        }
      }
    }).reduce((acc, v) => {
      return acc !== '' ? ` ${acc}, ${v}  ` : `${acc} ${v} `;
    }, '');
    return  this.values;
  }

//  TODO create search param mapping functions for each for each domain/type with different format
}
