#!/usr/bin/env python
"""
Compare tests results against precomputed reference results

Usage: validate_tests.py [-s <data_dir>] [-t]
  -s <data_dir>  Stage data from <data_dir>
  -t             Run tests
"""

import os
import re
from glob import glob
import argparse
import subprocess

script_dir = os.path.dirname(os.path.abspath(__file__))
os.chdir(script_dir)

# Subdirectories required to run tests
INPUT_DIRS = ['IR', 'VFA', 'dce', 'oe']

# Subdirectories with reference outputs
REF_OUT_DIRS = ['OE_output_maps', 'DCE_output_maps', 'madym_output']

# Correspondence map between data/* (reference) and output/* (test results)
# <pattern>:<replacement> regex operations (all applied, in order)
# - use <pat>:None to ignore files/dirs (stops any other rules)
MAP_REGEX_OPS = {
    '^OE_output_maps/': 'tools/deltaR1/',
    '^DCE_output_maps/': 'tools/deltaCt/',
    '^madym_output/T1_IR/': 'tools/IRE/',
    '^madym_output/T1_VFA/': 'tools/VFA/',
    '^madym_output/ETM_pop/': 'tools/ETM/',
    r'(Ct_.{3})/\1': r'\1',                              # e.g. Ct_mod/Ct_mod -> Ct_mod
    r'_\d{8}_\d{6}(_override)?_config.txt$': r'\1.cfg',  # consistent logs
    '^madym_output/T1_IR_noE/': None
}

# Filter pattern for files to compare
PATTERN = r'.*.nii.gz$'

verbose = False
def print_verbose(*args, **kwargs):
    if verbose:
        print(*args, **kwargs)

# PATTERN = r'.*\d_config.txt$'  # DEBUG

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("-s", "--data_dir", help="Stage data from <data_dir>")
    parser.add_argument("-t", "--run_tests", action="store_true", help="Run tests")
    parser.add_argument("-v", "--verbose", action="store_true")
    args = parser.parse_args()

    global verbose
    verbose = args.verbose

    # Stage data
    if args.data_dir:
        print_verbose(f"Staging data from {args.data_dir}")
        subprocess.run(["load_test_data.sh", args.data_dir] + INPUT_DIRS + REF_OUT_DIRS, check=True)

    # Run tests
    if args.run_tests:
        print_verbose("Running tests")
        subprocess.run(["run_tests.sh", "-t", "tools"], check=True)

    # Check (filtered) files in REF_OUT_DIRS
    for out_dir in [os.path.join('data', d) for d in REF_OUT_DIRS]:
        print_verbose(f"Checking {out_dir}")
        for ref_file in file_list(out_dir, PATTERN):

            test_file = translate_path(ref_file)

            if test_file is not None:
                compare_files(ref_file, test_file)
            else:
                print_verbose(f"Skipping {ref_file}")

def file_list(basedir, pattern='.*'):
    """
    List files in basedir (recursively) matching pattern
    """
    allfiles = glob(basedir + '/**/*', recursive=True)
    matched_files = [f for f in allfiles if re.match(pattern, f)]
    return matched_files    

def translate_path(filepath):
    """
    Apply MAP_REGEX_OPS to filepath data/* -> output/*
    """
    filepath = re.sub(r'^data/', '', filepath)

    for pat, rep in MAP_REGEX_OPS.items():
        if re.search(pat, filepath):
            if rep is None:
                return None
            else:
                filepath = re.sub(pat, rep, filepath)
    
    return os.path.join('output', filepath)

def compare_files(ref_file, test_file):
    """
    Compare `ref_file` with the corresponding `test_file`
    """

    if not os.path.exists(ref_file):
        raise FileNotFoundError(f"Missing {ref_file}")
    if not os.path.exists(test_file):
        print(f"Missing {test_file} for {ref_file}")   
        return

    if any(test_file.endswith(ext) for ext in ['.nii', '.nii.gz', '.img']):
        compare_maps(ref_file, test_file)
    elif test_file.endswith('.cfg'):
        compare_config(ref_file, test_file)
    else:
        compare_generic(ref_file, test_file)

def compare_maps(ref_file, test_file):
    compare_generic(ref_file, test_file)

def compare_config(ref_file, test_file):
    if verbose:
        flags = ["-s", "-w", "-y", "--suppress-common-lines"]
    else:
        flags = ["-q"]
    diff_process = subprocess.run(
        ["diff"] + flags + [ref_file, test_file], stdout=subprocess.PIPE)
    if diff_process.returncode != 0:
        print(f"Mismatch: {ref_file} != {test_file}")
    print_verbose(diff_process.stdout.decode())

def compare_generic(ref_file, test_file):
    if verbose:
        flags = ["-s"]
    else:
        flags = ["-q"]
    diff_process = subprocess.run(
        ["diff"] + flags + [ref_file, test_file], stdout=subprocess.PIPE)
    if diff_process.returncode != 0:
        print(f"Mismatch: {ref_file} != {test_file}")
    print_verbose(diff_process.stdout.decode())
    
if __name__ == "__main__":
    main()