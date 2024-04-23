#!/usr/bin/env cwl-runner
class: Workflow
cwlVersion: v1.2
label: Test workflow for utils/to_folder.cwl

requirements:
  - class: InlineJavascriptRequirement

inputs:
  file_names: 
    type: string[]
    default: ["foo", "bar"]
  folder_name: 
    type: string
    default: "bam/baz"

outputs:
  folder:
    type: Directory
    outputSource: to_folder/folder

steps:
  touch:
    in:
      names: file_names
    out: [files]
    run: utils:touch.cwl
  to_folder:
    in:
      content: touch/files
      name: folder_name
    out: [folder]
    run: utils:to_folder.cwl

$namespaces:
  utils: ../../utils/