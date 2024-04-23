#!/usr/bin/env cwl-runner
class: Workflow
cwlVersion: v1.2
label: Test workflow for utils/from_folder.cwl

requirements:
  - class: InlineJavascriptRequirement
  - class: MultipleInputFeatureRequirement

inputs:
  nested_files:
    type: string[]
    default: ["foo", "bar"]
  subfolder: 
    type: string
    default: "bam"
  other_files:
    type: string[]
    default: ["baz", "qux"]
  folder:
    type: string
    default: "some/path"
  file_list:
    type: string[]
    default: ["bam/foo", "bam/bar", "baz", "qux"]

outputs:
  files:
    type: File[]
    outputSource: from_folder/files

steps:
  touch_nested:
    in:
      names: nested_files
    out: [files]
    run: utils:touch.cwl
  to_subfolder:
    in:
      content: touch_nested/files
      name: subfolder
    out: [folder]
    run: utils:to_folder.cwl
  touch_other:
    in:
      names: other_files
    out: [files]
    run: utils:touch.cwl
  to_folder:
    in:
      content:
        source: [touch_other/files, to_subfolder/folder]
        linkMerge: merge_flattened
      name: folder
    out: [folder]
    run: utils:to_folder.cwl
  
  from_folder:
    in:
      basedir: to_folder/folder
      relpaths: file_list
    out: [files]
    run: utils:from_folder.cwl

$namespaces:
  utils: ../../utils/