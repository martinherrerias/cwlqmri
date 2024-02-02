#! /bin/bash
# Usage: run_tests.sh DATA [TEST]
# Run tests for *.cwl Command Line Tools
# DATA: directory containing input data
# TEST: test to run (IRE, VFA, deltaCt, all)

cd "$(git rev-parse --show-toplevel)"

DATA=$1
if [ ! -d "$DATA" ]; then
  echo "Invalid DATA directory: $DATA"
  exit 1
fi

TEST=${2:-all}

cmd="--cachedir test/cache"

case $TEST in
  IRE|VFA)
    input=madym_T1_${TEST}_test.yml
    tool=madym_T1.cwl
    ;;
  deltaCt)
    input=DCE_${TEST}_test.yml
    tool=DCE_${TEST}.cwl
    ;;
  all)
    for f in test/*.yml; do
      # extract key from test/*_<key>_test.yml
      key=${f%_test.yml}
      key=${key##*_}
      [[ -z "$key" ]] && continue
      . test/run_tests.sh "${DATA}" ${key}
    done
    exit 0
    ;;
  *)
    echo "Invalid TEST: ${TEST}"
    exit 1
    ;;
esac

mkdir -p test/output/${TEST}
echo Running: cwltool ${tool} ${input}
cp test/${input} ${DATA}
cwltool --outdir test/output/${TEST} \
        --cachedir test/cache ${tool} \
        ${DATA}/${input} > test/output/${TEST}/cwl.log 2>&1