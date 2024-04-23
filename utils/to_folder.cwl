#!/usr/bin/env cwl-runner

# SOURCE: https://github.com/rawgene/cwl/blob/master/tools/name.cwl
# Copyright (C) 2019 Alessandro Pio Greco, Patrick Hedley-Miller, Filipe Jesus, Zeyu Yang
# GNU General Public License <https://www.gnu.org/licenses/>

cwlVersion: v1.0
class: ExpressionTool
label: return directory with content items 
requirements:
  InlineJavascriptRequirement: {}

inputs:
  content: 
    type:
      - File
      - Directory
      - type: array
        items:
          - File
          - Directory
  name: string

outputs:
    folder: Directory

expression: |
  ${
    if (inputs.content.class == 'Directory'){
        return {
            'folder': {
                'class': 'Directory',
                'basename': inputs.name,
                'listing': [inputs.content]
            }
        }
    };
    if (inputs.content.class == 'File'){
        var arr = [inputs.content];
        }
    else {
        var arr = inputs.content;
    }
    return {
        'folder': {
            'class': 'Directory',
            'basename': inputs.name,
            'listing': arr
        }
    }
  }