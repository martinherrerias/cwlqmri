cwlVersion: v1.2
class: ExpressionTool
label: Return an array from a base directory and relative paths 

requirements:
  LoadListingRequirement: {loadListing: "deep_listing"}
  InlineJavascriptRequirement: {}

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

expression: |
  ${
    var arr = [];
    for (var i = 0; i < inputs.relpaths.length; i++) {

      var parts = inputs.relpaths[i].split("/");

      var item = inputs.basedir
      for (var j = 0; j < parts.length; j++) {
        item = item.listing.find(function(x) {
          return x.basename === parts[j];
        });
        if (!item) {
          throw "Item not found: " + inputs.relpaths[i];
        }
      }
      arr.push(item);
    }
    return {"files": arr}; 
  }