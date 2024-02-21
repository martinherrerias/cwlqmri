#! /bin/bash

read -r -d '' HELPSTR << HELPSTR
Usage: run_tests.sh [-n] [-c] [-t TESTSEQ] [...]
Run tests for *.cwl Command Line Tools or Workflows, using:

cwltool [...] --outdir output/<type>/<key> --cachedir cache/<key> \\
  ../*/<tool.cwl> ./*/<input.yml> > output/<tool.cwl>.log 2>&1

Where ../*/<tool.cwl> and ./*/<input.yml> are set according to each <key>
in the TESTSEQ, which is a sequence of keys to be tested:

    <key>  <tool.cwl>                <input.yml>
  ---------------------------------------------------------------------
  IRE|VFA  ../tools/madym_T1.cwl     ./tools/madym_T1_<key>_test.yml
      ETM  ../tools/madym_DCE.cwl    ./tools/madym_DCE_<key>_test.yml
  deltaCt  ../tools/DCE_deltaCt.cwl  ./tools/DCE_<key>_test.yml
  deltaR1  ../tools/OE_deltaR1.cwl   ./tools/OE_<key>_test.yml
    <key>  ../workflows/<key>.cwl    ./workflows/<key>_test.yml

The following meta-keys are also supported:

      tools - equivalent to IRE VFA ETM deltaCt deltaR1
  workflows - equivalent to OE_IR DCE_VFA OE_IR_DCE_VFA
        all - (default) tools followed by workflows

Options:
-t A B ... : run tests for the given keys in that order. -t "all" (default)
          stands for the sequence: IRE VFA deltaCt deltaR1
-n: dry run (print commands only)
-c: clean up (remove output and cache directories)
...: additional arguments to be passed to cwltool
HELPSTR

TOOLS=(IRE VFA ETM deltaCt deltaR1)
WORKFLOWS=(OE_IR DCE_VFA OE_IR_DCE_VFA)
ALL=(${TOOLS[@]} ${WORKFLOWS[@]})

# map keys to test-input/tool names
function input_name() {
  case $1 in
    IRE*|VFA*) echo "madym_T1_$1_test.yml";;
    ETM*) echo "madym_DCE_$1_test.yml";;
    deltaCt*) echo "DCE_$1_test.yml";;
    deltaR1*) echo "OE_$1_test.yml";;
    *) echo "$1_test.yml";;
  esac
}
function tool_name() {
  case $1 in
    IRE*|VFA*) echo "madym_T1.cwl";;
    ETM*) echo "madym_DCE.cwl";;
    deltaCt*) echo "DCE_deltaCt.cwl";;
    deltaR1*) echo "OE_deltaR1.cwl";;
    *) echo "$1.cwl";;
  esac
}

# Parse arguments
TESTSEQ=()
ARGS=()
dry_run=false
cleanup=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) echo "$HELPSTR"; exit 0;;
    -n) dry_run=true;;
    -c) cleanup=true;;
    -t)
      while [[ $# -gt 1 && ! "$2" =~ ^- ]]; do
        TESTSEQ+=("$2")
        shift
      done
      ;;
    *) ARGS+=("$1");;
  esac
  shift
done

cd "$( dirname "${BASH_SOURCE[0]}" )"

if [ $cleanup == true ]; then
  rm -rf output/* cache/*
  [ -z "${TESTSEQ[@]}" ] && exit 0
fi

# Handle special keys
[ -z "${TESTSEQ[@]}" ] && TESTSEQ=("all")
if [ ${#TESTSEQ[@]} -eq 1 ]; then
  case ${TESTSEQ[0]} in
    all) TESTSEQ=${ALL[@]};;
    tools) TESTSEQ=${TOOLS[@]};;
    workflows) TESTSEQ=${WORKFLOWS[@]};;
  esac
fi
echo "Test sequence: ${TESTSEQ[@]}"

[[ $dry_run == true ]] && echo "Dry run (would run):"
for key in ${TESTSEQ[@]}; do

  input=$(input_name $key)
  tool=$(tool_name $key)

  for type in "tools" "workflows"; do
    if [ -f "${type}/${input}" ] && [ -f "../${type}/${tool}" ]; then
      input="${type}/${input}"
      tool="../${type}/${tool}"
      break
    fi
  done

  if [ ! -f ${input} ] || [ ! -f ${tool} ]; then
    echo "Failed to find input file ${input} or tool file ${tool}"
    exit 1
  fi

  out="output/${type}/${key}"
  cache="cache/${key}"
  log="output/${tool##*/}.log"

  cmd="cwltool ${ARGS[@]} --outdir ${out} --cachedir ${cache} \
    ${tool} ${input} > ${log} 2>&1"

  if [ $dry_run == true ]; then
    echo ${cmd}
    continue
  fi

  mkdir -p ${out}
  rm -f ${out}/*
  echo Running: ${cmd}
  eval $cmd

  if [ $? -eq 0 ]; then
    echo "Test ${key} passed"
  else
    echo "Test ${key} failed! See ${log} for details."
    exit 1
  fi
done