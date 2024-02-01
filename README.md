# cwl_madym

CWL tool wrappers for [*QBI-Madym*](https://gitlab.com/manchester_qbi/manchester_qbi_public/madym_cxx),
a *C++* toolkit for Quantative MRI analysis developed in the Quantitative Biomedical Imaging Laboratory at the University of Manchester.

The tools are meant to be integrated into a workflow manager: https://github.com/UoMResearchIT/radnet_core_pipelines/

Developed in the framework of the [*RADNET* project](https://github.com/orgs/UoMResearchIT/projects/39). 

## Requirements

- [Docker](https://www.docker.com/)
- [CWL](https://www.commonwl.org/) runner, e.g. [cwltool](https://github.com/common-workflow-language/cwltool)

## Tool tests

```bash
# Place input files somewhere where their relative paths make sense
DATA=<path/to/test/data>
cp test/madym_T1_IRE_test.yml $DATA
cp test/madym_T1_VFA_test.yml $DATA

# Test CLI tools
cwltool --outdir test/output/IRE --cachedir test/cache madym_T1.cwl $DATA/madym_T1_IRE_test.yml
cwltool --outdir test/output/VFA --cachedir test/cache madym_T1.cwl $DATA/madym_T1_VFA_test.yml
```
> **TODO**: generate synthetic data and automate tests
