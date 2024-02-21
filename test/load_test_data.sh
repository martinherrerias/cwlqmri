#! /bin/bash
# Usage: ./load_test_data.sh <DATA_DIR> [REQ]
# Create symlinks to the required subdirectories REQ in ./test/data/*
# DATA_DIR: directory containing input data
# REQ: list of required subdirectories, default: (dce oe IR VFA)

cd "$( dirname "${BASH_SOURCE[0]}" )"
mkdir -p data

DATA=$1
if [ ! -d "$DATA" ]; then
    echo "Invalid DATA directory: $DATA"
    exit 1
fi
shift

REQ=($@)
[ ${#REQ[@]} -eq 0 ] && REQ=(dce oe IR VFA)

echo "Staging: (${REQ[@]}) from ${DATA}"

for r in ${REQ[@]}; do
    if [ ! -d "$DATA/$r" ]; then
        echo "Failed to find: $DATA/$r"
        exit 1
    fi
    if [ -L "data/$r" ]; then
        rm data/$r
    fi
    ln -s -T $DATA/$r data/$r
done