#! /bin/bash
# Usage: run_tests.sh [TESTSEQ]
# Run tests for *.cwl Command Line Tools
# TESTSEQ: test sequence, default "all" = IRE VFA deltaCt deltaR1

cd "$( dirname "${BASH_SOURCE[0]}" )"

TESTSEQ=${1:-"all"}
[[ $TESTSEQ == "all" ]] && TESTSEQ="IRE VFA deltaCt deltaR1"

cmd="--cachedir cache"

for TEST in ${TESTSEQ[@]}; do

  case $TEST in
    IRE|VFA)
      input=madym_T1_${TEST}_test.yml
      tool=../madym_T1.cwl
      ;;
    deltaCt)
      input=DCE_${TEST}_test.yml
      tool=../DCE_${TEST}.cwl
      ;;
    deltaR1)
      input=OE_${TEST}_test.yml
      tool=../OE_${TEST}.cwl
      ;;
    *)
      echo "Invalid TEST: ${TEST}"
      exit 1
      ;;
  esac

  mkdir -p output/${TEST}
  echo Running: cwltool ${tool} ${input}
  cwltool --outdir output/${TEST} \
          --cachedir cache ${tool} \
          ${input} > output/${TEST}/cwl.log 2>&1

  if [ $? -eq 0 ]; then
    echo "Test ${TEST} passed"
  else
    echo "Test ${TEST} failed! See output/${TEST}/cwl.log for details."
    exit 1
  fi
done