#!/bin/bash
set -euo pipefail

######################### SETUP ###########################

# Define pipeline root
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Define pipeline name
PIPELINE_NAME="$(basename "${ROOT_DIR}")"
# Define script name
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"

######################### SOURCE ##########################

source "${ROOT_DIR}/config.sh"                                  # User configuration
source "${ROOT_DIR}/functions/functions_base.sh"                # Base pipeline functions

######################### LOGS ############################

# Define log directory
LOG_DIR="${ROOT_DIR}/logs"
# Make log directory
mkdir -p "${LOG_DIR}"
# Define log file for this script
LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}.log"
# Redirect stdout/stderr to terminal and log file
exec > >(tee -a "${LOG_FILE}") 2>&1

######################### PREFLIGHT #######################

echo
echo "PREFLIGHT for ${PIPELINE_NAME} ..."

# Run preflight.sh orchestrator
source "${ROOT_DIR}/preflight/preflight.sh"

echo
echo "PREFLIGHT for ${PIPELINE_NAME} COMPLETE"

######################### MAIN ############################

echo
echo "RUNNING ${SCRIPT_NAME} ..."

echo
echo "  User configuration:"
echo "    Reference genome FASTA:        ${REF_FASTA}"
echo "    CPUs allocated:                ${BWA_CPUS}"

echo
echo "  Scripts to run:"

for script in "${PIPELINE_ARRAY[@]}"; do
    echo "    ${script}"
done

echo
echo "  Submitting pipeline.sh ..."

# Run pipeline.sh orchestrator
PIPELINE_JOB_ID=$(
    sbatch \
        --parsable \
        --job-name=genome-index \
        --export="${SBATCH_EXPORTS}" \
        --output="${LOG_DIR}/pipeline.%j.log" \
        "${PIPELINE_DIR}/pipeline.sh"
) || fail_message "Failed to submit pipeline.sh"

echo
echo "${SCRIPT_NAME} COMPLETE"
echo "Pipeline ID: ${PIPELINE_JOB_ID}"