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
      - The following override the madym_T1 defaults:
        - `use_BIDS` defaults to TRUE
        - `img_fmt_r` defaults to `NIFTI_GZ`
        - `img_fmt_w`is set to track `img_fmt_r`
      - Settings like `data_dir`, `output_dir`, `maps_dir`, `overwrite`
        are set to work with CWL, i.e. reading all inputs from the staging
        directory, and writing all outputs to the output directory.
      - Logs are time-stamped and suffixed by madym: `madym_T1_{date}_{time}_{log.ext}`
        where `{log.ext}` is the value of the `--program_log`, `--config_out`, and
        `--autit` options, respectively. This wrapper renames them to a consistent
        `madym_T1.{ext}`, with extensions `.log`, `.cfg`, and `.audit`.

hints:
  DockerRequirement:
    dockerPull: registry.gitlab.com/manchester_qbi/preclinical_mri/core_pipelines:latest
  SoftwareRequirement:
    packages:
      - package: madym_T1
        version: [ "v4.24.0" ]

requirements:
  InlineJavascriptRequirement: {}
  # ShellCommandRequirement: {}
  InitialWorkDirRequirement:
    listing: $(inputs.T1_vols)
  SchemaDefRequirement:
    types:
      - $import: utils:custom_types.yml
baseCommand: madym_T1
arguments:
  # See NOTES
  - prefix: --output_root
    valueFrom: $(runtime.outdir)
  - prefix: --output
    valueFrom: ""
  - prefix: --audit_dir
    valueFrom: $(runtime.outdir)
  - prefix: --audit
    valueFrom: cwl.audit # renamed by logs/outputEval
  - prefix: --program_log
    valueFrom: cwl.log # ..
  - prefix: --config_out
    valueFrom: cwl.cfg # ..
  - prefix: --overwrite
    valueFrom: "1"
  
# Deliberately not included
# -cwd 
# --config

inputs:
  T1_vols:
    label: File paths to input signal volumes
    type: File[]
    secondaryFiles:
      - pattern: ^^.json
        required: $(inputs.img_fmt_r.startsWith("NIFTI"))
      - pattern: ^.hrd
        required: $(inputs.img_fmt_r == "ANALYZE")
      - pattern: ^.xtr
        required: false
    inputBinding:
      prefix: --T1_vols
      itemSeparator: ", "
  img_fmt_r:
    label: Image format of input signal volumes
    doc: |
      NIFTI_GZ / NIFTI will read all compressed and uncompressed NIFTI, and ANALYZE images 
      However, `img_fmt_r` gets mapped as the default for `img_fmt_w` where the choice does matter.
    default: NIFTI_GZ
    type: utils:custom_types.yml#image_format?
    inputBinding:
      prefix: --img_fmt_r
  img_fmt_w:
    label: Image format for writing output
    type:
      - utils:custom_types.yml#image_format
      - type: enum
        symbols: [ "same_as_input" ]
    default: "same_as_input"
    inputBinding:
      prefix: --img_fmt_w
      valueFrom: |
        $(self !== "same_as_input" ? self : inputs.img_fmt_r)

  T1_method:
    label: Method used for baseline T1 mapping
    default: IR_E
    type: utils:custom_types.yml#T1_method
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
    # format: ??, secondaryFiles: ??
    inputBinding:
      prefix: --B1
  TR:
    label: TR of dynamic series (ms)
    type: double?
    inputBinding:
      prefix: --TR
  T1_init_params:
    label: Initial values for [T1, M0] to be optimised
    doc: |
      If only 1 set, this will initialise T1.
    type: double[]?
    inputBinding:
      prefix: --T1_init_params
      itemSeparator: ", "
  roi:
    label: Path to ROI map
    type: File?
    # format: ??, secondaryFiles: ??
    inputBinding:
      prefix: --roi
  err:
    label: Path to existing error tracker map
    doc: if empty, a new map is created
    type: File?
    # format: ??, secondaryFiles: ??
    inputBinding:
      prefix: --err
  nifti_4D:
    label: Read NIFTI 4D images for T1 mapping and dynamic inputs? 
    type: boolean?
    inputBinding:
      prefix: --nifti_4D
  nifti_scaling:
    label: Apply intensity scaling and offset when reading/writing NIFTI images
    type: boolean?
    inputBinding:
      prefix: --nifti_scaling
  use_BIDS:
    label: Read/Write images using BIDS json meta info (default TRUE)
    default: true
    type: boolean?
    inputBinding:
      prefix: --use_BIDS
  voxel_size_warn_only:
    label: warning only if image sizes do not match
    doc:  Only throw a warning (instead of error) if input image voxel sizes do not match
    type: boolean?
    inputBinding:
      prefix: --voxel_size_warn_only
  no_log:
    label: Switch off program logging
    type: boolean?
    inputBinding:
      prefix: --no_log
  quiet:
    label: Do not display logging messages in cout
    type: boolean?
    inputBinding:
      prefix: -q
  no_audit:
    label: Switch off audit logging
    type: boolean?
    inputBinding:
      prefix: --no_audit

outputs:
  efficiency:
    type: File?
    secondaryFiles: [^^.json, ^.hdr, ^.xtr]
    outputBinding: 
      glob: [efficiency.nii*, efficiency.img]
  T1:
    type: File
    secondaryFiles: [^^.json, ^.hdr, ^.xtr]
    outputBinding: 
      glob: [T1.nii*, T1.img]
  M0:
    type: File
    secondaryFiles: [^^.json, ^.hdr, ^.xtr]
    outputBinding: 
      glob: [M0.nii*, M0.img]
  error_tracker:
    type: File
    secondaryFiles: [^^.json, ^.hdr, ^.xtr]
    outputBinding: 
      glob: [error_tracker.nii*, error_tracker.img]
  logs:
    type: File[]
    outputBinding:
      glob: madym_T1_*_cwl.*
      outputEval: | # Remove timestamps: *_{date}_{time}(_*)_cwl.{ext} -> *(_*).{ext}
        ${
          self.forEach(function(f) {
            f.basename = f.basename.replace(/_\d{8}_\d{6}/, "").replace(/_cwl/, "");
            return f;
          });
          return self;
        }

$namespaces:
  utils: ../utils/
#   edam: http://edamontology.org/
#   iana: https://www.iana.org/assignments/media-types/