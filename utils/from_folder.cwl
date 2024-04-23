cwlVersion: v1.2
class: CommandLineTool
label: Return an array from a base directory and relative paths 

requirements:
  - class: InlineJavascriptRequirement
    expressionLib:  
      - |
        function contentfilter(relpaths, basedir) {
          var arr = [];
          for (var i = 0; i < relpaths.length; i++) {

            var parts = relpaths[i].split("/");

            var item = basedir
            for (var j = 0; j < parts.length; j++) {
              item = item.listing.find(function(x) {
                return x.basename === parts[j];
              });
              if (!item) {
                throw "Item not found: " + relpaths[i];
              }
            }
            arr.push(item);
          }
          return arr;
        }
  - class: InitialWorkDirRequirement
    listing:
      - entry: $(contentfilter(inputs.relpaths, inputs.basedir))

baseCommand: echo

inputs:
  relpaths: string[]
  basedir: Directory

outputs:
  files: 
    type:
      - type: array
        items:
          - File
          - Directory
    outputBinding:
      outputEval: $(contentfilter(inputs.relpaths, inputs.basedir))
