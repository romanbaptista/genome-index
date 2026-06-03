#!/bin/bash
set -euo pipefail

######################### GUARDS #########################

GUARD_ARRAY=(
    FUNCTIONS_DIR
    ARRAY_DIR
    LOG_DIR
    PIPELINE_DIR
    BWA_CPUS
    SBATCH_EXPORTS
)

for var in "${GUARD_ARRAY[@]}"; do
    : "${!var:?${var} not set or empty}"
done

######################### SETUP ###########################

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"

######################### SOURCE ##########################

source "${FUNCTIONS_DIR}/functions_base.sh"
source "${ARRAY_DIR}/array_pipeline.sh"    

######################### CHECKS #########################

variable_check_nonempty PIPELINE_ARRAY || fail_message "PIPELINE_ARRAY is empty or not defined"
array_check_nonempty PIPELINE_ARRAY || fail_message "PIPELINE_ARRAY has no elements"

######################### LOGS ###########################

LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}.log"
exec > >(tee -a "${LOG_FILE}") 2>&1

######################### MAIN ###########################

echo
echo "RUNNING ${SCRIPT_NAME} ..."

echo
echo "  Scripts to run:"

for script in "${PIPELINE_ARRAY[@]}"; do
    echo "      ${script}"
done

echo "  SUBMITTING refindex.sh ..."

REFINDEX=$(
    sbatch \
        --parsable \
        --job-name=genome-index-pipeline \
        --export="${SBATCH_EXPORTS}" \
        --cpus-per-task="${BWA_CPUS}" \
        --output="${LOG_DIR}/refindex.%j.log" \
        "${PIPELINE_DIR}/refindex.sh"
) || fail_message "Failed to submit refindex.sh"

echo "  refindex.sh SUBMITTED"
echo "${SCRIPT_NAME} COMPLETE"
echo "Job ID: ${REFINDEX}"