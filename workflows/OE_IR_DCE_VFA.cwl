cwlVersion: v1.2
class: Workflow
label: OE-IR and DCE-VFA T1 mapping and DCE analysis
doc: |
    Combines two independent chains: OE-IR, and DCE-VFA, merged at the end to
    generate summary statistics and maps.

requirements:
  InlineJavascriptRequirement: {}
  SubworkflowFeatureRequirement: {}
  MultipleInputFeatureRequirement: {}
  SchemaDefRequirement:
    types:
      - $import: utils:custom_types.yml

inputs:
# T1 mapping inputs
  OE_T1_vols:
    type: File[]
    secondaryFiles:
      - pattern: ^^.json
        required: true
  OE_T1_method:
    default: IR_E
    type: utils:custom_types.yml#T1_method

# T1 mapping inputs
  DCE_T1_vols:
    type: File[]
    secondaryFiles:
      - pattern: ^^.json
        required: true
  DCE_T1_method:
    default: VFA
    type: utils:custom_types.yml#T1_method

# Are these common to both chains?
  T1_noise:
    type: double
    default: 0.1
  B1_scaling:
    type: double
    default: 1000
  B1: File?
  TR: double?

# deltaR1 inputs
  oe_path: 
    type: File
    secondaryFiles:
      - pattern: ^^.json
        required: true
  oe_limits: int[]

# DCE_deltaCt
  dce_path:
    type: File
    secondaryFiles:
      - pattern: ^^.json
        required: true
  dce_limits: int[]
  relax_coeff: double

# Are these common to both chains?
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
  logs:
    type: File[]
    outputSource: [OE_IR/logs, DCE_VFA/logs]
    linkMerge: merge_flattened
    # outputSource: IR/logs

steps:
  OE_IR:
    run: OE_IR.cwl
    in:
      T1_vols: OE_T1_vols
      T1_method: OE_T1_method
      T1_noise: T1_noise
      B1_scaling: B1_scaling
      B1: B1
      TR: TR
      nifti_scaling: nifti_scaling
      use_BIDS: use_BIDS
      voxel_size_warn_only: voxel_size_warn_only
      quiet: quiet
      oe_path: oe_path
      oe_limits: oe_limits
      average_fun: average_fun
      alternative: alternative
      equal_var: equal_var
      roi: roi
      no_log: no_log
      no_audit: no_audit  
    out: [efficiency, T1, M0, error_tracker, 
          R1_t, delta_R1, R1_baseline, R1_enhancing, R1_p_vals, S_p_vals, logs]
  
  DCE_VFA:
    run: DCE_VFA.cwl
    in:
      T1_vols: DCE_T1_vols
      T1_method: DCE_T1_method
      T1_noise: T1_noise
      B1_scaling: B1_scaling
      B1: B1
      TR: TR

      dce_path: dce_path
      dce_limits: dce_limits
      relax_coeff: relax_coeff
      average_fun: average_fun
      alternative: alternative
      equal_var: equal_var

      dyn_dir: dyn_dir
      dyn: dyn
      Ct: Ct
      inj: inj
      M0_ratio: M0_ratio
      r1: r1

      aif: aif
      aif_map: aif_map
      pif: pif
      hct: hct
      dose: dose

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

      Ct_sig: Ct_sig
      Ct_mod: Ct_mod
      iauc: iauc
      iauc_peak: iauc_peak

      roi: roi
      nifti_scaling: nifti_scaling
      use_BIDS: use_BIDS
      voxel_size_warn_only: voxel_size_warn_only
      no_audit: no_audit
      no_log: no_log
      quiet: quiet

    out: [T1, M0, C_t, delta_C, C_baseline, C_enhancing, C_p_vals, S_p_vals, 
          IAUC, Ktrans, enhVox, error_tracker, residuals, stats, Ct_mod, Ct_sig, params, logs]

$namespaces:
  utils: ../utils/