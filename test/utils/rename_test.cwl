#!/usr/bin/env cwl-runner
class: Workflow
cwlVersion: v1.2
label: Test workflow for utils/rename.cwl

requirements:
  - class: InlineJavascriptRequirement

inputs:
  names: 
    type: string[]
    default: ["foo.txt", "bar.csv"]
  pattern: 
    type: string
    default: "(.*)\\.txt$"
  replace: 
    type: string
    default: "the_$1.log"

outputs:
  renamed:
    type: File[]
    outputSource: rename/renamed

steps:
  touch:
    in:
      names: names
    out: [files]
    run: utils:touch.cwl
  rename:
    in:
      files: touch/files
      pattern: pattern
      replace: replace
    out: [renamed]
    run: utils:rename.cwl

$namespaces:
  utils: ../../utils/