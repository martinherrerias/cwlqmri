cwlVersion: v1.2
class: ExpressionTool
label: rename files using regexp pattern / replace
requirements:
  InlineJavascriptRequirement: {}
inputs:
  files: File[]
  pattern: string
  replace: string
outputs:
  renamed: File[]
expression: |
  ${
    var pattern = new RegExp(inputs.pattern);
    inputs.files.map(function(f) {
      f.basename = f.basename.replace(pattern, inputs.replace);
      return f;
    });
    return {"renamed": inputs.files};
  }