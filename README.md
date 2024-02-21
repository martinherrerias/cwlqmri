# cwl_madym

CWL tool wrappers and workflow templates for [*QBI-Madym*](https://gitlab.com/manchester_qbi/manchester_qbi_public/madym_cxx),
a *C++* toolkit for Quantative MRI analysis developed in the Quantitative Biomedical Imaging Laboratory at the University of Manchester.

The tools are meant to be integrated into a workflow manager: <https://github.com/UoMResearchIT/radnet_core_pipelines/>

Developed in the framework of the [*RADNET* project](https://github.com/orgs/UoMResearchIT/projects/39). 

## Requirements

- [Docker](https://www.docker.com/)
- [CWL](https://www.commonwl.org/) runner, e.g. [cwltool](https://github.com/common-workflow-language/cwltool)

## Tools

- `madym_T1.cwl`: T1 mapping from Inversion Recovery (IR) or Variable Flip Angle (VFA) data
- `madym_DCE.cwl`: fits tracer-kinetic models to Dynamic Contrast Enhanced (DCE) time-series
- `DCE_deltaCt.cwl`: calculates change in contrast agent concentration C(t) from DCE time-series
- `OE_deltaR1.cwl`: calculates change in R1 relaxation rate from Oxygen Enhanced (OE) time-series
- `OE_DCE_summary.cwl` [*PENDING!*]: apply ROI masks to DCE and OE data and calculate summary statistics

# Workflows

- `OE_IR`: `madym_T1 (IR_E)` + `OE_deltaR1`
- `DCE_VFA`: `madym_T1 (VFA)` + `OE_deltaCt` + `madym_DCE (ETM)`
- `OE_IR_DCE_VFA`: `OE_IR` + `DCE_VFA` + [*PENDING!*] `OE_DCE_summary`

## Tests

There's an example input file for each tool/workflow in the `test` directory.
Relative file paths ares set to work with data placed under `test/data`.
The script `load_test_data.sh` will to place symlinks to the required subdirectories (dce, oe, IR, VFA) in the right place: 

```bash
bash test/load_test_data.sh <DATA_DIR> [<sub-directories>]
```

If the data does not conform to this structure, the input files will need to be edited accordingly. Relative paths are interpreted as relative to the input file's location.

The script `run_tests.sh` will attempt to run (all) tests on the linked data, generating output in `test/output`. To test a given tool or workflow, use the `-t` option, e.g.:

```bash
bash test/run_tests.sh -t OE_IR_DCE_VFA
```

This is equivalent to the `cwltool` command:

```bash
# cd ./test
cwltool --outdir output/workflows/OE_IR_DCE_VFA --cachedir cache/OE_IR_DCE_VFA \
    ../workflows/OE_IR_DCE_VFA.cwl workflows/OE_IR_DCE_VFA_test.yml > output/OE_IR_DCE_VFA.cwl.log 2>&1
```

> **TODO**: generate synthetic data and automate tests
