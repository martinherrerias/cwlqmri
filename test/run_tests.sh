#! /bin/bash

# Usage: run_tests.sh [-n] [-c] [-t TESTSEQ] [...]
# Run tests for *.cwl Command Line Tools or Workflows, using:
#
#   cwltool --outdir output/<key> --cachedir cache [...] \
#    ../<tool.cwl> <tool-test.yml> > output/<key>/cwl.log 2>&1
#
# Where <tool.cwl> and <tool-test.yml> are set according to each <key>
#
# Options:
# -t A B ... : run tests for the given keys in that order. -t "all" (default)
#           stands for the sequence: IRE VFA deltaCt deltaR1
# -n: dry run (print commands only)
# -c: clean up (remove output and cache directories)
# ...: additional arguments to be passed to cwltool

DEF_SEQ=(IRE VFA deltaCt deltaR1)

cd "$( dirname "${BASH_SOURCE[0]}" )"

TESTSEQ=()
ARGS=()
dry_run=false
cleanup=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    -t)
      shift
      while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
        TESTSEQ+=("$1")
        shift
      done
      ;;
    -n)
      dry_run=true
      shift
      ;;
    -c)
      rm -rf cache/*
      cleanup=true
      shift
      ;;
    *)
      ARGS+=("$1")
      shift
      ;;
  esac
done
if [ -z "${TESTSEQ[@]}" ] || [ "${TESTSEQ[@]}" == "all" ]; then
  TESTSEQ=${DEF_SEQ[@]}
fi

echo "Test sequence: ${TESTSEQ[@]}"
[[ $dry_run == true ]] && echo "Dry run (would run):"
for TEST in ${TESTSEQ[@]}; do

  case $TEST in
    IRE*|VFA*)
      input=madym_T1_${TEST}_test.yml
      tool=../madym_T1.cwl
      ;;
    deltaCt*)
      input=DCE_${TEST}_test.yml
      tool=../DCE_${TEST}.cwl
      ;;
    deltaR1*)
      input=OE_${TEST}_test.yml
      tool=../OE_${TEST}.cwl
      ;;
    ETM*)
      input=madym_DCE_${TEST}_test.yml
      tool=../madym_DCE.cwl
      ;;
    *)
      # Generic/new/custom) test
      input=${TEST}_test.yml
      tool=../${TEST}.cwl
      ;;
  esac

  if [ ! -f ${input} ] || [ ! -f ${tool} ]; then
    echo "Failed to find input file ${input} or tool file ${tool}"
    exit 1
  fi

  cmd="cwltool --outdir output/${TEST} --cachedir cache ${ARGS[@]} \
                ${tool} ${input} > output/${TEST}/cwl.log 2>&1"

  if [ $dry_run == true ]; then
    echo ${cmd}
    continue
  fi

  mkdir -p output/${TEST}
  rm -f output/${TEST}/*
  echo Running: ${cmd}
  eval $cmd

  if [ $? -eq 0 ]; then
    echo "Test ${TEST} passed"
  else
    echo "Test ${TEST} failed! See output/${TEST}/cwl.log for details."
    exit 1
  fi
done