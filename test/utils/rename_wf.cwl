#!/usr/bin/env cwl-runner
class: Workflow
cwlVersion: v1.2

requirements:
  - class: InlineJavascriptRequirement

inputs:
  names: string[]
  pattern: string
  replace: string

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