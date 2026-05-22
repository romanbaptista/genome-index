#!/bin/bash
set -euo pipefail

######################### GUARDS ##########################

: "${UTILS_DIR:?UTILS_DIR not set (check PATHS section in run_pipeline.sh)}"
: "${SAMTOOLS_MODULE:?SAMTOOLS_MODULE not set (check arrays.sh)}"

######################### SETUP ##########################

# Define script name
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}" .sh)
# Define toolname
TOOLNAME="samtools"

######################## SOURCE ##########################

# Source arrays.sh
source  "${UTILS_DIR}/arrays.sh"
# Source tool-specific functions
source "${UTILS_DIR}/functions_${TOOLNAME}.sh"

######################### MAIN ############################

echo "  RUNNING ${SCRIPT_NAME} ..."
echo "  Loading ${TOOLNAME} module..."

# Attempt to load module
module load "${SAMTOOLS_MODULE}" || fail "  Failed to load module: ${SAMTOOLS_MODULE}"

echo "  Checking module functionality..."
check_samtools || fail "  ${TOOLNAME} functionality not found: 'faidx'"

echo "  Module loaded and functionality confirmed: ${TOOLNAME}"
echo "  ${SCRIPT_NAME} COMPLETE"