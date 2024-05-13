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

See [test/README.md](test/README.md) for instructions on running tests.
