cwlVersion: v1.2
class: Workflow
label: OE-IR -- madym_T1 (IR_E) + OE_deltaR1
doc: |
    Calculates T1 map using Inversion Recovery (with Efficiency weighting), 
    estimates R1(t) from OE signal S(t), and the IR [efficiency,] and T1 maps,
    then compares the average R1(t) for the baseline and enhancing periods.

    NOTES:
        - `nifti_4D` is hard-set to FALSE
        - `img_fmt_r`/`img_fmt_w` are hard-set to `NIFTI_GZ` (id.)

requirements:
  InlineJavascriptRequirement: {}
  MultipleInputFeatureRequirement: {}
  SchemaDefRequirement:
    types:
      - $import: utils:custom_types.yml

inputs:
# T1 mapping inputs
  T1_vols:
    type: File[]
    secondaryFiles:
      - pattern: ^^.json
        required: true
  T1_method:
    default: IR_E
    type: utils:custom_types.yml#T1_method
  T1_noise:
    type: double
    default: 0.1
  B1_scaling:
    type: double
    default: 1000
  B1: File?
  TR: double?
  T1_init_params: double[]?

  nifti_scaling: boolean?
  use_BIDS:
    default: true
    type: boolean?
  voxel_size_warn_only: boolean?
  quiet: boolean?

# deltaR1 inputs
  oe_path: 
    type: File
    secondaryFiles:
      - pattern: ^^.json
        required: true
  oe_limits: int[]
  average_fun:
    default: median
    type: utils:custom_types.yml#average_method?
  alternative:
    default: less
    type: utils:custom_types.yml#hypothesis_test?
  equal_var:
    default: false
    type: boolean?

# common inputs
  roi: File?
  no_log: boolean?
  no_audit: boolean?

outputs:
  efficiency:
    type: File?
    outputSource: IR/efficiency
  T1:
    type: File
    outputSource: IR/T1
  M0:
    type: File
    outputSource: IR/M0
  error_tracker:
    type: File
    outputSource: IR/error_tracker
  R1_t:
    type: File
    outputSource: deltaR1/R1_t
  delta_R1:
    type: File
    outputSource: deltaR1/delta_R1
  R1_baseline:
    type: File
    outputSource: deltaR1/R1_baseline
  R1_enhancing:
    type: File
    outputSource: deltaR1/R1_enhancing
  R1_p_vals:
    type: File
    outputSource: deltaR1/R1_p_vals
  S_p_vals:
    type: File
    outputSource: deltaR1/S_p_vals
  logs:
    type: File[]
    outputSource: [IR/logs, deltaR1/logs]
    linkMerge: merge_flattened
    # outputSource: IR/logs

steps:
  IR:
    run: tools:madym_T1.cwl
    in:
      T1_vols: T1_vols
      T1_method: T1_method
      T1_noise: T1_noise
      B1_scaling: B1_scaling
      B1: B1
      TR: TR
      T1_init_params: T1_init_params
      roi: roi
      nifti_4D:
        default: false
      img_fmt_r:
        default: NIFTI_GZ
      nifti_scaling: nifti_scaling
      use_BIDS: use_BIDS
      voxel_size_warn_only: voxel_size_warn_only
      no_log: no_log
      quiet: quiet
      no_audit: no_audit
    out: [efficiency, T1, M0, error_tracker, logs]

  deltaR1:
    run: tools:OE_deltaR1.cwl
    in:
      T1_path: IR/T1
      efficiency_path: IR/efficiency
      roi_path: roi
      oe_path: oe_path
      oe_limits: oe_limits
      average_fun: average_fun
      alternative: alternative
      equal_var: equal_var
      no_log: no_log
    out: [R1_t, delta_R1, R1_baseline, R1_enhancing, R1_p_vals, S_p_vals, logs]

$namespaces:
  tools: ../tools/
  utils: ../utils/