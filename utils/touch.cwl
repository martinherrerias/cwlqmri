class: CommandLineTool
cwlVersion: v1.2

baseCommand: touch

inputs:
  names:
    type: string[]
    inputBinding:
      position: 1

outputs:
  files:
    type: File[]
    outputBinding:
      glob: $(inputs.names)

