#! /bin/bash

cd "$( dirname "${BASH_SOURCE[0]}" )"

read -r -d '' HELPSTR << HELPSTR
Compare tests results against precomputed reference results

Usage: $0 [-s <data_dir>] [-t]
  -s <data_dir>  Stage data from <data_dir>
  -t             Run tests
HELPSTR

# Subdirectories required to run tests
INPUT_DIRS=(IR VFA dce oe)

# Subdirectories with reference outputs
REF_OUT_DIRS=(OE_output_maps DCE_output_maps madym_output)

# Correspondence map between data/* (reference) and output/* (test results)
# Use -- to ignore a directory
declare -A MAP=(
  ["OE_output_maps"]="tools/deltaR1"
  ["DCE_output_maps"]="tools/deltaCt"
  ["madym_output/T1_IR"]="tools/IRE"
  ["madym_output/T1_VFA"]="tools/VFA"
  ["madym_output/ETM_pop"]="tools/ETM"
  ["madym_output/T1_IR_noE"]="--"
)

# Map equivalent subdirectories from data/* to output/*
translate_path() {
  local ref="$1"
  local dir="${ref%/*}"
  local file="${ref##*/}"
  local mapped="${MAP[$dir]}"
  if [[ -n "$mapped" ]]; then
    if [[ "$mapped" == "--" ]]; then
      echo ""
    else
      echo "${mapped}/${file}"
    fi
  else
    echo "$ref"
  fi
}

# file_list <base> <subdirs> will return a list <subdir>/**.nii.gz
file_list() {
  cd "$1";
  local -n dirs=$2
  for d in "${dirs[@]}"; do
    find -L $d -type f -name *.nii.gz
  done
}

run_tests=false
DATA=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help) echo "$HELPSTR"; exit 0;;
    -s) DATA="$2";
        [ ! -d "${DATA}" ] && echo "Data directory '${DATA}' not found" && exit 1
        shift;;
    -t) run_tests=true;;
    *) echo "Unknown argument $1"; exit 1;;
  esac
  shift
done

# Stage data
if [ ! -z "${DATA}" ]; then
  bash ./load_test_data.sh ${DATA} ${INPUT_DIRS[@]} ${REF_OUT_DIRS[@]}
fi

# Run tests
[ $run_tests == true ] && bash ./run_tests.sh -t tools

for ref_file in $(file_list data REF_OUT_DIRS); do
  translated=$(translate_path "$ref_file")
  [[ -z "$translated" ]] && continue
  if [[ ! -f "output/$translated" ]]; then
    echo "Missing output/$translated for data/$ref_file"
  else
    diff -q "data/$ref_file" "output/$translated" > /dev/null
    if [[ $? -ne 0 ]]; then
      echo "Mismatch: $ref_file <> $translated"
    fi
  fi
done