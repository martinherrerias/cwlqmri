cwlVersion: v1.2
class: CommandLineTool
label: madym_DCE tool wrapper
doc: |
    Madym is a C++ toolkit for quantative DCE-MRI and DWI-MRI analysis developed 
    in the QBI Lab at the University of Manchester.

    This CWL wrapper is for the `madym_DCE` tool. It fits tracer-kinetic models
    to DCE time-series stored in Analyze/NIFTI format images, saving the model
    parameters and modelled concentration time-series also in Analyze/NIFTI format.    
    
    REFERENCES:
      - Berks et al., (2021). Madym: A C++ toolkit for quantitative DCE-MRI analysis.
        Journal of Open Source Software, 6(66), 3523, https://doi.org/10.21105/joss.03523
    
      - https://gitlab.com/manchester_qbi/manchester_qbi_public/madym_cxx/-/wikis/madym_DCE

    NOTES:
      - The following override the madym_DCE defaults:
        - `use_BIDS` defaults to TRUE
        - `img_fmt_r` defaults to `NIFTI_GZ`
        - `img_fmt_w`is set to track `img_fmt_r`
      - Settings like `data_dir`, `output_dir`, `maps_dir`, `overwrite`
        are set to work with CWL, i.e. reading all inputs from the staging
        directory, and writing all outputs to the output directory.
      - Logs are time-stamped and suffixed by madym: `madym_DCE_{date}_{time}_{log.ext}`
        where `{log.ext}` is the value of the `--program_log`, `--config_out`, and
        `--autit` options, respectively. This wrapper renames them to a consistent
        `madym_DCE.{ext}`, with extensions `.log`, `.cfg`, and `.audit`.

hints:
  DockerRequirement:
    dockerPull: registry.gitlab.com/manchester_qbi/preclinical_mri/core_pipelines:latest
  SoftwareRequirement:
    packages:
      - package: madym_DCE
        version: [ "v4.24.0" ]

requirements:
  InlineJavascriptRequirement: {}
  # ShellCommandRequirement: {}
  SchemaDefRequirement:
    types:
      - $import: utils:custom_types.yml

baseCommand: madym_DCE
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
# --Ct_sig_prefix --Ct_mod_prefix
# --config
  
inputs:
# Dynamic Input data
  Ct:
    label: Is input dynamic sequence concentration (not signal) maps?
    doc: |
      If `Ct` is set, the following arguments are ignored:
      `T1_method`, `T1_vols`, `T1_noise`, `T1`, `M0`, `M0_ratio`, `r1`
    type: boolean?
    inputBinding:
      prefix: --Ct
  nifti_4D:
    label: Read NIFTI 4D images for T1 mapping and dynamic inputs? 
    doc: |
      If set, the following arguments are ignored (see `dyn`):
      `n_dyns`, `sequence_format`, `sequence_start`, `sequence_step`
    type: boolean?
    inputBinding:
      prefix: --nifti_4D
  dyn_dir:
    label: Folder containing dynamic volumes
    type: Directory
    inputBinding:
      prefix: --dyn_dir
  dyn:
    label: (Root) name for dynamic volumes
    doc: |
      If `nifti_4D` is set, a single input map is expected, with name
        <dyn_dir>/<dyn>.nii[.gz].
      For ANALYZE (.hdr, .img) pairs, several arguments are combined to create
      a template name for matching dynamic volumes, of the form:
        <dyn_dir>/<dyn><i>.<ext>, where <i> is an index formatted according
      to `sequence_format`, starting at `sequence_start` and stepping by
      `sequence_step` (including up to `n_dyns` volumes).
    type: string?
    default: dyn_
    inputBinding:
      prefix: -d
  sequence_format:
    label: Number format for suffix specifying temporal index of volumes in a sequence
    type: string?
    default: "%01u"
    inputBinding:
      prefix: --sequence_format
  sequence_start:
    label: Start index volumes in a sequence
    type: int?
    default: 1
    inputBinding:
      prefix: --sequence_start
  sequence_step:
    label: Step index volumes in a sequence
    type: int?
    default: 1
    inputBinding:
      prefix: --sequence_step
  n_dyns:
    label: Number of DCE volumes
    doc: if 0, uses all images matching file pattern
    type: int?
    default: 0
    inputBinding:
      prefix: -n
  inj:
    label: Injection image
    type: int?
    default: 8
    inputBinding:
      prefix: -i
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

# T1 mapping/converting signal to concentration
  T1_method:
    label: Method used for baseline T1 mapping
    default: VFA
    type: utils:custom_types.yml#T1_method?
    inputBinding:
      prefix: --T1_method
  T1_vols:
    label: File paths to input signal volumes
    type: File[]?
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
  T1_noise:
    label: Noise threshold for fitting baseline T1
    type: double?
    default: 0
    inputBinding:
      prefix: --T1_noise
  TR:
    label: Repetition Time of dynamic series (ms)
    type: double?
    inputBinding:
      prefix: --TR
  M0_ratio:
    label: Use ratio method to scale signal instead of precomputed M0?
    type: boolean?
    default: true
    inputBinding:
      prefix: --M0_ratio
  T1:
    label: Path to precomputed T1 map
    type: File?
    # format: ??, secondaryFiles: ??
    inputBinding:
      prefix: --T1
  M0:
    label: Path to precomputed M0 map
    type: File?
    # format: ??, secondaryFiles: ??
    inputBinding:
      prefix: --M0
  r1:
    label: Relaxivity constant of concentration in tissue
    type: double?
    default: 3.4
    inputBinding:
      prefix: --r1

  # B1 correction (for VFA T1 mapping, and correcting the FA)
  B1_scaling:
    label: Scaling value appplied to B1 map
    type: double?
    default: 1000
    inputBinding:
      prefix: --B1_scaling
  B1:
    label: Path to B1 correction map
    type: File?
    # format: ??, secondaryFiles: ??
    inputBinding:
      prefix: --B1
  B1_correction:
    label: Use B1 correction on FA values to scale signal instead of precomputed M0?
    type: boolean?
    default: false
    inputBinding:
      prefix: --B1_correction

  # Vascular input functions
  aif:  
    label: Path to precomputed AIF, if not set uses Parker population AIF
    type: File?
    # format: ??, secondaryFiles: ??
    inputBinding:
      prefix: --aif
  aif_map:
    label: Map of voxels to average in AIF computation
    type: File?
    # format: ??, secondaryFiles: ??
    inputBinding:
      prefix: --aif_map
  pif:
    label: Path to precomputed PIF, if not set will use Banerji method for deriving from AIF
    type: File?
    # format: ??, secondaryFiles: ??
    inputBinding:
      prefix: --pif
  hct:
    label: Haematocrit correction
    type: double?
    default: 0.42
    inputBinding:
      prefix: -H
  dose:
    label: Contrast-agent dose (mmol per kg)
    doc: only required if using population estimate of AIF
    type: double?
    default: 0.1
    inputBinding:
      prefix: -D

  # Tracer-kinetic model fitting
  model:
    label: Tracer-kinetic model to fit
    type: utils:custom_types.yml#tracer_kinetic_model
    inputBinding:
      prefix: -m
  first:
    label: First image used in model fit cost function
    doc: |
      First image to use computing RSS (or WSS) for tracer-kinetic
      model fitting. If 0 (default), starts from beginning of series.
    type: int?
    default: 0
    inputBinding:
      prefix: --first
  last:
    label: Last image used in model fit cost function
    doc: |
      Last image to use computing RSS (or WSS) for tracer-kinetic
      model fitting. If 0 (default), uses all images in series.
    type: int?
    default: 0
    inputBinding:
      prefix: --last
  no_opt:
    label: Turn-off optimisation, just fit initial parameters values for model.
    type: boolean?
    default: false
    inputBinding:
      prefix: --no_opt
  dyn_noise:
    label: Use varying temporal noise in model fit
    type: boolean?
    default: false
    inputBinding:
      prefix: --dyn_noise
  test_enh:
    label: Test for enhancement before fitting model
    type: boolean?
    default: true
    inputBinding:
      prefix: --test_enh
  max_iter:
    label: Max iterations per voxel in optimisation
    doc: 0 for no limit
    type: int?
    default: 0
    inputBinding:
      prefix: --max_iter
  opt_type:
    label: Type of optimisation to use
    type: utils:custom_types.yml#optim_method?
    default: BLEIC
    inputBinding:
      prefix: --opt_type
  
  # Initializing/fixing tracer-kinetic model parameters
  init_params:
    label: Initial values for model parameters to be optimised
    type: double[]?
    inputBinding:
      prefix: --init_params
      itemSeparator: ", "
  init_maps:
    label: Path to folder containing to parameters to initialise fit (overrides `init_params`)
    type: Directory?
    inputBinding:
      prefix: --init_maps
  init_map_params:
    label: Index of parameters sampled from maps
    doc: If empty and `init_maps` set, takes all params from input maps.
    type: int[]?
    inputBinding:
      prefix: --init_map_params
      itemSeparator: ", "
  residuals_map:
    label: Path to model residuals map as a target threshold for new fits
    type: File?
    # format: ??, secondaryFiles: ??
    inputBinding:
      prefix: --residuals
  param_names:
    label: Names of model parameters, used to override default output map names
    type: string[]?
    inputBinding:
      prefix: --param_names
      itemSeparator: ", "
  fixed_params:
    label: Index of parameters fixed to their initial values (i.e. not optimised)
    type: int[]?
    inputBinding:
      prefix: --fixed_params
      itemSeparator: ", "
  fixed_values:
    label: Values for fixed parameters (overrides default initial parameter values).
    type: double[]?
    inputBinding:
      prefix: --fixed_values
      itemSeparator: ", "
  lower_bounds:
    label: Lower bounds for each parameter during optimisation
    type: double[]?
    inputBinding:
      prefix: --lower_bounds
      itemSeparator: ", "
  upper_bounds:
    label: Upper bounds for each parameter during optimisation
    type: double[]?
    inputBinding:
      prefix: --upper_bounds
      itemSeparator: ", "
  relative_limit_params:
    label: Index of parameters to which relative limits are applied
    type: int[]?
    inputBinding:
      prefix: --relative_limit_params
      itemSeparator: ", "
  relative_limit_values:
    label: Values for relative limits
    doc: |
      Optimiser capped to range `k` +/- `d` where `k` is the inital parameter
      value and `d` is the relative limit.
    type: double[]?
    inputBinding:
      prefix: --relative_limit_values
      itemSeparator: ", "
  repeat_param:
    label: Index of parameter at which repeat fits will be made
    type: int?
    default: -1
    inputBinding:
      prefix: --repeat_param
  repeat_values:
    label: Values for repeat parameter
    type: double[]?
    inputBinding:
      prefix: --repeat_values
      itemSeparator: ", "
  
  # Output options
  save_Ct_sig:
    label: Save signal-derived dynamic concentration maps
    type: boolean?
    default: true
    inputBinding:
      prefix: --Ct_sig
  save_Ct_mod:
    label: Save modelled dynamic concentration maps
    type: boolean?
    default: true
    inputBinding:
      prefix: --Ct_mod
  iauc:
    label: Times (in s, post-bolus injection) at which to compute IAUC
    type: int[]?
    default: [60, 90, 120]
    inputBinding:
      prefix: -I
      itemSeparator: ", "
  iauc_peak:
    label: Compute IAUC at peak signal
    type: boolean?
    default: true
    inputBinding:
      prefix: --iauc_peak
  
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
      prefix: --voxel_size_warn_only 1
      shellQuote: false
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
    default: true
    inputBinding:
      prefix: --no_audit

outputs:
  IAUC:
    type: File[]
    secondaryFiles: [^^.json, ^.hdr, ^.xtr]
    outputBinding:
      glob: [IAUC*.nii*, IAUC*.img]
      outputEval: |
        ${
          // Sort by time, e.g. IAUC_90 before IAUC_120
          self.sort(function(a, b) {
            return a.basename.localeCompare(b.basename, undefined, {numeric: true});
          });
          return self;
        }
  Ktrans:
    type: File
    secondaryFiles: [^^.json, ^.hdr, ^.xtr]
    outputBinding:
      glob: [Ktrans.nii*, Ktrans.img]
  enhVox:
    type: File
    secondaryFiles: [^^.json, ^.hdr, ^.xtr]
    outputBinding:
      glob: [enhVox.nii*, enhVox.img]
  error_tracker:
    type: File
    secondaryFiles: [^^.json, ^.hdr, ^.xtr]
    outputBinding: 
      glob: [error_tracker.nii*, error_tracker.img]
  residuals:
    type: File
    secondaryFiles: [^^.json, ^.hdr, ^.xtr]
    outputBinding:
      glob: [residuals.nii*, residuals.img]
  stats:
    type: File[]
    outputBinding:
      glob: ["*.txt", "*.csv"]
  Ct_mod:
    type: File?
    secondaryFiles: [^^.json, ^.hdr, ^.xtr]
    outputBinding:
      glob: [Ct_mod/Ct_mod*.nii*, Ct_mod/Ct_mod*.img]
  Ct_sig:
    type: File?
    secondaryFiles: [^^.json, ^.hdr, ^.xtr]
    outputBinding:
      glob: [Ct_sig/Ct_sig*.nii*, Ct_sig/Ct_sig*.img]
  params:
    type: File[]
    secondaryFiles: [^^.json, ^.hdr, ^.xtr]
    outputBinding:
      glob: ["*.nii.*", "*.img"]
      outputEval: |
        ${
          // Remove maps included in other outputs
          self = self.filter(function(f) {
            return !f.basename.startsWith("IAUC") && 
                   !f.basename.startsWith("Ktrans") &&
                   !f.basename.startsWith("enhVox") && 
                   !f.basename.startsWith("error_tracker") &&
                   !f.basename.startsWith("residuals");
          });
          return self;
        }
  logs:
    type: File[]
    outputBinding:
      glob: "madym_DCE_*_cwl.*"
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