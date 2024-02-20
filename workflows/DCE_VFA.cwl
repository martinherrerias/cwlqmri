cwlVersion: v1.2
class: Workflow
label: DCE_VFA -- madym_T1 (VFA) + OE_deltaCt + madym_DCE (ETM)
doc: |
    DCE-VFA (Dynamic Contrast Enhanced MRI using Variable Flip Angle)
    1. Calculates T1 map using Variable Flip Angle (VFA) data
    2. Estimates C(t) from DCE signal S(t) and the VFA T1, and compares the
      average C(t) for the baseline and enhancing periods.
    3. Fits a tracer-kinetic model to DCE time-series data (using VFA T1 map).

    NOTES:
        - `nifti_4D` is hard-set to TRUE (required for OE_deltaR1.cwl)
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
    default: VFA
    type: utils:custom_types.yml#T1_method
  T1_noise:
    type: double
    default: 0.1
  B1_scaling:
    type: double
    default: 1000
  B1: File?
  TR: double?

# DCE_deltaCt
  dce_path:
    type: File
    secondaryFiles:
      - pattern: ^^.json
        required: true
  dce_limits: int[]
  relax_coeff: double
  average_fun:
    default: median
    type: utils:custom_types.yml#average_method?
  alternative:
    default: less
    type: utils:custom_types.yml#hypothesis_test?
  equal_var:
    default: false
    type: boolean?

# DCE
  dyn_dir: Directory
  dyn: string?
  Ct: boolean
  inj: int?
  M0_ratio: boolean
  # M0: File?
  r1: double?

  # Vascular input functions
  aif: File?
  aif_map: File?
  pif: File?
  hct: double?
  dose: double?

  # Tracer-kinetic model fitting
  model: 
    default: ETM
    type: utils:custom_types.yml#tracer_kinetic_model
  first: int?
  last: int?
  no_opt: boolean?
  dyn_noise: boolean?
  test_enh: boolean?
  max_iter: int?
  opt_type: utils:custom_types.yml#optim_method?
  
  # Initializing/fixing tracer-kinetic model parameters
  init_params: double[]?
  init_maps: Directory?
  init_map_params: int[]?
  residuals: File?
  param_names: string[]?
  fixed_params: int[]?
  fixed_values: double[]?
  lower_bounds: double[]?
  upper_bounds: double[]?
  relative_limit_params: int[]?
  relative_limit_values: double[]?
  repeat_param: int?
  repeat_values: double[]?

  # Output options
  Ct_mod: boolean?
  Ct_sig: boolean?
  iauc: int[]?
  iauc_peak: boolean?

# Common inputs
  roi: File?
  nifti_scaling: boolean?
  use_BIDS: boolean?
  voxel_size_warn_only: boolean?
  no_audit: boolean?
  no_log: boolean?
  quiet: boolean?

outputs:
# VFA
  T1:
    type: File
    outputSource: VFA/T1
  M0:
    type: File
    outputSource: VFA/M0
# deltaCt
  C_t:
    type: File
    outputSource: deltaCt/C_t
  delta_C:
    type: File
    outputSource: deltaCt/delta_C
  C_baseline:
    type: File
    outputSource: deltaCt/C_baseline
  C_enhancing:
    type: File
    outputSource: deltaCt/C_enhancing
  C_p_vals:
    type: File
    outputSource: deltaCt/C_p_vals
  S_p_vals:
    type: File
    outputSource: deltaCt/S_p_vals
# ETM
  IAUC:
    type: File[]
    outputSource: ETM/IAUC
  Ktrans:
    type: File
    outputSource: ETM/Ktrans
  enhVox:
    type: File
    outputSource: ETM/enhVox
  error_tracker:
    type: File
    outputSource: ETM/error_tracker
  residuals:
    type: File
    outputSource: ETM/residuals
  stats:
    type: File[]
    outputSource: ETM/stats
  Ct_mod:
    type: File?
    outputSource: ETM/Ct_mod
  Ct_sig:
    type: File?
    outputSource: ETM/Ct_sig
  params:
    type: File[]
    outputSource: ETM/params
# Combined logs
  logs:
    type: File[]
    outputSource: [VFA/logs, deltaCt/logs, ETM/logs]
    linkMerge: merge_flattened

steps:
  VFA:
    run: tools:madym_T1.cwl
    in:
      T1_vols: T1_vols
      T1_method: T1_method
      T1_noise: T1_noise
      B1_scaling: B1_scaling
      B1: B1
      TR: TR
      roi: roi
      nifti_4D:
        default: true
      img_fmt_r:
        default: NIFTI_GZ
      nifti_scaling: nifti_scaling
      use_BIDS: use_BIDS
      voxel_size_warn_only: voxel_size_warn_only
      no_log: no_log
      quiet: quiet
      no_audit: no_audit
    out: [efficiency, T1, M0, error_tracker, logs]

  deltaCt:
    run: tools:DCE_deltaCt.cwl
    in:
      T1_path: VFA/T1
      roi_path: roi
      dce_path: dce_path
      dce_limits: dce_limits
      relax_coeff: relax_coeff
      average_fun: average_fun
      alternative: alternative
      equal_var: equal_var
      no_log: no_log
    out: [C_t, delta_C, C_baseline, C_enhancing, C_p_vals, S_p_vals, logs]

  ETM:
    run: tools:madym_DCE.cwl
    in:
    # Input maps
      err: VFA/error_tracker
      T1: VFA/T1
      roi: roi
      dyn_dir: dyn_dir
      dyn: dyn
      Ct: Ct
      inj: inj
      M0_ratio: M0_ratio
      r1: r1
      nifti_4D:
        default: true
      img_fmt_r:
        default: NIFTI_GZ
    # Vascular input functions
      aif: aif
      aif_map: aif_map
      pif: pif
      hct: hct
      dose: dose
    # Tracer-kinetic model fitting
      model: model
      first: first
      last: last
      no_opt: no_opt
      dyn_noise: dyn_noise
      test_enh: test_enh
      max_iter: max_iter
      opt_type: opt_type
      init_params: init_params
      init_maps: init_maps
      init_map_params: init_map_params
      residuals: residuals
      param_names: param_names
      fixed_params: fixed_params
      fixed_values: fixed_values
      lower_bounds: lower_bounds
      upper_bounds: upper_bounds
      relative_limit_params: relative_limit_params
      relative_limit_values: relative_limit_values
      repeat_param: repeat_param
      repeat_values: repeat_values
    # Output options
      Ct_sig: Ct_sig
      Ct_mod: Ct_mod
      iauc: iauc
      iauc_peak: iauc_peak
    # Common inputs
      use_BIDS: use_BIDS
      voxel_size_warn_only: voxel_size_warn_only
      no_log: no_log
      quiet: quiet
      no_audit: no_audit
    out: [IAUC, Ktrans, enhVox, error_tracker, residuals, stats, Ct_mod, Ct_sig, params, logs]

$namespaces:
  tools: ../tools/
  utils: ../utils/