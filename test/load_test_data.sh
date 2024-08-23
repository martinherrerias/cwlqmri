#! /bin/bash
# Copy one of the reference `processed` data sets in [1] to `./test/data/`
# Namely:
#
#   TEST_DATA/processed/SES/SUB -> test/data/SUB, for each SUB in REQ
#   TEST_DATA/roi/ROI -> test/data/roi_masks/my_roi.nii, where ROI matches SES
#
# Usage: load_test_data.sh TEST_DATA SES [REQ]
#
#   TEST_DATA: path to `test_data` clone [1]
#   SES: session ID (e.g. 20230705_142924_230408_1_1) or index (e.g. 1)
#   REQ: required DATA_DIR subdirectories, default:
#       (dce oe IR VFA madym_output DCE_output_maps OE_output_maps)
#
# [1] https://gitlab.com/manchester_qbi/preclinical_mri/test_datasets

DATA=$1
if [[ ! "$DATA" = /* ]]; then
    DATA=$(pwd)/$DATA # absolute path
fi
DATA=${DATA%/} # remove trailing slash
if [ ! -d "$DATA" ]; then
    echo "Invalid DATA directory: $DATA"
    exit 1
fi
shift

SES=$1
shift
if [[ "$SES" =~ ^[0-9]$ ]]; then
    SES=$(ls $DATA/processed | sed -n "${SES}p") # get SES by index
fi

ACQ="${DATA}/processed/${SES}"
if [ ! -d "$ACQ" ]; then
    echo "Invalid ACQ directory: $ACQ"
    exit 1
fi

YYMMDD=$(echo $SES | cut -d_ -f3) # extract YYMMDD from SES=########_######_YYMMDD_1_1
ROI="${DATA}/roi/*_${YYMMDD}.nii*"
ROI=$(eval ls "$ROI")
if [ ! -f "$ROI" ]; then
    echo "Invalid ROI map: $ROI"
    exit 1
fi

cd "$( dirname "${BASH_SOURCE[0]}" )"
mkdir -p data

REQ=($@)
[ ${#REQ[@]} -eq 0 ] && REQ=(dce oe IR VFA madym_output DCE_output_maps OE_output_maps)

copy () {
    local src=$1
    local tgt=$2
    if [ ! -e "$src" ]; then
        echo "Failed to find: $src"
        exit 1
    fi
    if [ -e "$tgt" ]; then
        rm -rd $tgt
    fi
    cp -r $src $(dirname $tgt)
}

echo "Copying: ${ACQ}/SUB to data/SUB"
echo "    for SUB in ( ${REQ[@]} )"
for r in ${REQ[@]}; do
    copy $ACQ/$r data/$r
done

# get ROI extension
EXT=.nii${ROI##*.nii}

echo "Copying: ${ROI} to data/roi_masks/my_roi${EXT}"
mkdir -p data/roi_masks
rm data/roi_masks/*
cp "${ROI}" "data/roi_masks/my_roi${EXT}"