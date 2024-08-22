
# Unit Tests

## Setup

There's a test `*.yml` input file for each tool/workflow in the `test` directory.
Relative file paths are set to work with data placed under `test/data`.
The script `load_test_data.sh` will place symlinks to the required subdirectories (`dce`, `oe`, `IR`, ... , `OE_output_maps`) in the expected locations: 

```bash
bash test/load_test_data.sh DATA_DIR
```

Where `DATA_DIR` is a reference (processed) acquisition directory, e.g. 
`test_datasets/processed/20230705_142924_230408_1_1` from [test_datasets](https://gitlab.com/manchester_qbi/preclinical_mri/core_pipelines).

If the data does not conform to this structure, the input files will need to be edited accordingly. Relative paths are interpreted as relative to the input file's location.

## Running Tests

Unit tests are defined in `test_descriptions.yml` using the [CWLTest](https://cwltest.readthedocs.io/) framework. They can be run using the `cwltest` command-line tool:

```
pip install cwltest
cwltest --test test/test_descriptions.yml --tool cwltool
```

See `cwltest --help` for options to run individual (or subsets of) tests, e.g.:

```
# See a list of tests, and run the third one
cwltest --test test_descriptions.yml --tool cwltool -l
cwltest --test test_descriptions.yml --tool cwltool -n 3

# See a list of tags, and run tests with a specific tag
cwltest --test test_descriptions.yml --tool cwltool --show-tags
cwltest --test test_descriptions.yml --tool cwltool --tags "madym"
```

## Writing Tests

The [CONFORMANCE_TESTS.md](https://github.com/common-workflow-language/cwl-v1.2/blob/main/CONFORMANCE_TESTS.md) document in the CWL specification repo seems to be the only useful documentation available.

For examples, see the CWL spec. test description file: [conformance_tests.yaml](https://github.com/common-workflow-language/cwl-v1.2/blob/main/conformance_tests.yaml)


## TODO

- Generate synthetic data (to avoid dependency on external data)
- Add output file hashes (currently only checking for existence of output files)
- Automate tests using CI/CD (e.g. GitHub Actions)

