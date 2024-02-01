cwlVersion: v1.2
class: CommandLineTool
label: PreclinicalMRI.dynamic.compute_dataset_delta_Ct tool wrapper
doc: |
    Delta-C(t) for Dynamic Contrast Enhanced (DCE) MRI analysis pipelines.
    Estimates concentration C(t) from signal S(t) and T1 maps, then compares
    the average C(t) for the baseline and enhancing periods.

    (CWL wrapper for PreclinicalMRI.dynamic.dce.compute_dataset_delta_Ct)
    
    REFERENCES:
      - Preclinical MRI Wiki. <https://gitlab.com/manchester_qbi/preclinical_mri/core_pipelines/-/wikis/home>
      - Wrapped function: <https://gitlab.com/manchester_qbi/preclinical_mri/core_pipelines/-/blob/main/src/PreclinicalMRI/dynamic/dce.py>

    NOTES:

hints:
  DockerRequirement:
    dockerPull: ghcr.io/uomresearchit/radnet/preclinicalmri/core_pipelines:latest

requirements:
  - class: InlineJavascriptRequirement
  - class: ShellCommandRequirement
  - class: InitialWorkDirRequirement
    listing: 
      - $(inputs.dce_path)

baseCommand: python -m PreclinicalMRI.pipelines.qMRI_processes.DCE_deltaCt
arguments:
  # - prefix: --data_dir
  #   valueFrom: $(runtime.outdir)
  - prefix: --output_dir
    valueFrom: $(runtime.outdir)
  # - prefix: --audit_dir
  #   valueFrom: $(runtime.outdir)
  # - prefix: --audit_log
  #   valueFrom: .audit # see NOTES
  - prefix: --program_log
    valueFrom: .log # see NOTES
  - prefix: --config_log
    valueFrom: .cfg # see NOTES
  - prefix: --overwrite
    valueFrom: "1"
  - prefix: --no_audit
    valueFrom: "1"
  
inputs:
  dce_path:
    label: Path to DCE data
    doc: |
      Relative path to the DCE data S(t), default 'dynamic'
    type: Directory
    inputBinding:
      prefix: --dce_path
  dce_limits:
    label: Baseline and enhancing time periods [B0, B1, E0, E1]
    doc: |
      4 element integer list [B0, B1, E0, E1], specifying the baseline and enhancing time periods
      B1 is also used to set the time points to use for M0 calculation.
    type: int[]
    inputBinding:
      prefix: --dce_limits
      valueFrom: |
        [$(inputs.dce_limits.join(', '))]
  dce_im_ext:
    label: File extension for the DCE data
    default: .nii.gz
    type: string
    inputBinding:
      prefix: --dce_im_ext
  dce_meta_ext:
    label: File extension for the DCE meta data
    default: .json
    type: string
    inputBinding:
      prefix: --dce_meta_ext
  T1_path:
    label: Path to T1 map
    doc: Relative path to the T1 map (required)
    type: File
    inputBinding:
      prefix: --T1_path
  roi_path:
    label: Path to ROI map
    type: File?
    # format: ??
    inputBinding:
      prefix: --roi_path
  relax_coeff:
    label: Relaxivity coefficient for the contrast agent (ms)
    default: 0
    type: double
    inputBinding:
      prefix: --relax_coeff
  average_fun:
    label: Method used for temporal average{median, mean}
    default: median
    type: 
      type: enum
      symbols:
        - median
        - mean
    inputBinding:
      prefix: --average_fun
  alternative:
    label: Hypothesis t-test {'two-sided', 'less', 'greater'}
    doc: |
      'less' (default) = baseline lower than enhancing.
      'two-sided' = baseline different to enhancing.
      'greater' = baseline higher than enhancing.
    default: less
    type: 
      type: enum
      symbols:
        - two-sided
        - less
        - greater
    inputBinding:
      prefix: --alternative
  equal_var:
    label: Assume equal variance in pre/post enhancing periods
    default: true
    type: boolean?
    inputBinding:
      prefix: --equal_var 1
      shellQuote: false
  maps_dir:
    label: Location of saved output maps, relative to data_dir
    default: DCE_output_maps
    type: Directory
    inputBinding:
      prefix: --maps_dir
  no_log:
    label: Switch off program logging
    type: boolean?
    inputBinding:
      prefix: --no_log 1
      shellQuote: false

outputs:
  C_t:
    label: Concentration time series
    type: File
    outputBinding:
      glob: "C_t.*"
  delta_C:
    label: Difference between enhancing and baseline periods
    type: File
    outputBinding:
      glob: "delta_C.*"
  C_baseline:
    label: Average concentration in baseline period
    type: File
    outputBinding:
      glob: "C_baseline.*"
  C_enhancing:
    label: Average concentration in enhancing period
    type: File
    outputBinding:
      glob: "C_enhancing.*"
  C_p_vals:
    label: P-values comparing concentration in baseline vs enhancing periods
    type: File
    outputBinding:
      glob: "C_p_vals.*"
  S_p_vals:
    label: P-values comparing signal in baseline vs enhancing periods
    type: File
    outputBinding:
      glob: "S_p_vals.*"
  logs:
    type: File[]
    outputBinding:
      glob: run_DCE_deltaCt.*
      outputEval: | # Rename: run_DCE_deltaCt.{ext}{date}_{time}.txt -> DCE_deltaCt.{ext}
        ${
          self.forEach(function(f) {
            f.basename = f.basename.replace(/\d{8}_\d{6}.txt/, "").replace(/run_/, "");
            return f;
          });
          return self;
        }

# $namespaces:
#   edam: http://edamontology.org/
#   iana: https://www.iana.org/assignments/media-types/