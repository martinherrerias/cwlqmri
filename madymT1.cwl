cwlVersion: v1.2
class: CommandLineTool
label: madym_T1 tool wrapper
doc: |
    Madym is a C++ toolkit for quantative DCE-MRI and DWI-MRI analysis developed 
    in the QBI Lab at the University of Manchester.

    This CWL wrapper is for the madym_T1 tool, applying the Variable Flip Angle method
    [with B1 correction], or the Inversion Recovery method [with efficiency weighting]
    to a set of input signal volumes.
    
    REFERENCES:
      - Berks et al., (2021). Madym: A C++ toolkit for quantitative DCE-MRI analysis.
        Journal of Open Source Software, 6(66), 3523, https://doi.org/10.21105/joss.03523
    
      - https://gitlab.com/manchester_qbi/manchester_qbi_public/madym_cxx/-/wikis/madym_t1

    NOTES:
      - Logs are time-stamped and auto-renamed by madym, e.g. `madym_T1_{date}_{time}_{log}`
        where `{log}` is the value of the `--program_log option`. This wrapper renames them
        to a consistent name, e.g. `madym_T1_{method}.log`

hints:
  DockerRequirement:
    dockerPull: registry.gitlab.com/manchester_qbi/manchester_qbi_public/madym_cxx/madym_release_no_gui:u22.04
  SoftwareRequirement:
    packages:
      - package: madym_T1
        version: [ "v4.15.1" ]

requirements:
  InlineJavascriptRequirement: {}

baseCommand: madym_T1
arguments:
  - prefix: "--cwd"
    valueFrom: $(runtime.outdir)
  - prefix: "--img_fmt_r"
    valueFrom: $(inputs.T1_vols[0].format)
  - prefix: "--output_root"
    valueFrom: $(runtime.outdir)
  - prefix: "--output"
    valueFrom: ""
  - prefix: "--audit_dir"
    valueFrom: $(runtime.outdir)
  - "--audit_log cwl.audit" # see NOTES
  - "--program_log cwl.log" # see NOTES
  - "--config_out cwl.conf" # see NOTES
  - "--overwite 1"

inputs:
  T1_vols:
    label: Filepaths to input signal volumes
    doc: e.g. from Variable Flip Angles
    type: File[]
    secondaryFiles:
      - ^.json
    format:
      - NIFTI
      - NIFTI_GZ
      - ANALYZE
      - ANALYZE_SPARSE
      - DICOM # not implemented?
      # TODO: use edam ontology for formats? would need parsing to pass to madym
      #   NIFTI = edam:format_4001, DICOM = edam:format_3548, the rest seem not to be in edam
    inputBinding:
      prefix: --T1_vols
  img_fmt_w:
    label: Image format for writing output
    default: $(inputs.img_fmt_r)
    type:
      type: enum
      symbols:
        - NIFTI
        - NIFTI_GZ
        - ANALYZE
        - ANALYZE_SPARSE
        - DICOM # not implemented?
    inputBinding:
      prefix: --img_fmt_w
  T1_method:
    label: Method used for baseline T1 mapping
    doc: |
      VFA - Variable Flip-Angle
      VFA_B1 - Variable Flip-Angle (B1 corrected)
      IR - Inversion Recovery
      IR_E - Inversion Recovery (with efficiency weighting)
    default: IR_E
    type: 
      type: enum
      symbols:
        - VFA
        - VFA_B1
        - IR
        - IR_E
    inputBinding:
      prefix: --T1_method
  T1_noise:
    label: Noise threshold for fitting baseline T1
    type: double
    default: 0.1
    inputBinding:
      prefix: --T1_noise
  B1_scaling:
    label: Scaling value appplied to B1 map
    type: double
    default: 1000
    inputBinding:
      prefix: --B1_scaling
  B1:
    label: Path to B1 correction map
    type: File?
    # format: ??
    inputBinding:
      prefix: --B1
  TR:
    label: TR of dynamic series (ms)
    type: double?
    inputBinding:
      prefix: --TR
  roi:
    label: Path to ROI map
    type: File?
    # format: ??
    inputBinding:
      prefix: --roi
  err:
    label: Path to existing error tracker map
    doc: if empty, a new map is created
    type: File?
    # format: ??
    inputBinding:
      prefix: --err
  # {nifti_4D, nifti_scaling, and use_BIDS} are not in `madym_T1 -h`
  # but are passed by the python wrapper
  nifti_4D:
    label: Read NIFTI 4D images for T1 mapping and dynamic inputs
    type: boolean?
    inputBinding:
      prefix: "--nifti_4D 1"
  nifti_scaling:
    label: Apply intensity scaling and offset when reading/writing NIFTI images
    type: boolean?
    inputBinding:
      prefix: "--nifti_scaling 1"
  use_BIDS:
    label: Write images using BIDS json meta info
    type: boolean?
    inputBinding:
      prefix: "--use_BIDS 1"
  voxel_size_warn_only:
    label: warning only if image sizes do not match
    doc:  Only throw a warning (instead of error) if input image voxel sizes do not match
    type: boolean?
    inputBinding:
      prefix: "--voxel_size_warn_only 1"
  no_log:
    label: Switch off program logging
    type: boolean?
    inputBinding:
      prefix: "--no_log 1"
  quiet:
    label: Do not display logging messages in cout
    type: boolean?
    inputBinding:
      prefix: -q
  no_audit:
    label: Switch off audit logging
    type: boolean?
    inputBinding:
      prefix: "--no_audit 1"

outputs:
  efficiency_map:
    type: File[]
    outputBinding:
      glob: "efficiency.*"
  T1_map:
    type: File[]
    outputBinding:
      glob: "T1.*"
  M0_map:
    type: File[]
    outputBinding:
      glob: "M0.*"
  error_tracker:
    type: File
    outputBinding:
      glob: "error_tracker.*"
  log:
    type: File
    outputBinding:
      glob: "*cwl.log"
      outputEval: ${self[0].basename = "madym_T1_" + inputs.T1_method + ".log"; return self;}
  config:
    type: File
    outputBinding:
      glob: "*!(*override*)cwl.cfg" # ignore override config
      outputEval: ${self[0].basename = "madym_T1_" + inputs.T1_method + ".cfg"; return self;}
  audit:
    type: File
    outputBinding:
      glob: "*cwl.audit"
      outputEval: ${self[0].basename = "madym_T1_" + inputs.T1_method + ".audit"; return self;}

# $namespaces:
#   edam: http://edamontology.org/
#   iana: https://www.iana.org/assignments/media-types/