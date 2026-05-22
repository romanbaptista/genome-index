#!/bin/bash
set -euo pipefail

######################### GUARDS ##########################

GUARD_ARRAY=(
    LOG_DIR
    MODULES_DIR
    BWA_CPUS
)

for var in "${GUARD_ARRAY[@]}"; do
    : "${!var:?${var} not set or not exported (check run_pipeline.sh)}"
done

######################### SETUP ###########################

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"

######################### LOGS ############################

LOG_FILE="${LOG_DIR}/${SCRIPT_NAME}.log"
exec > >(tee -a "${LOG_FILE}") 2>&1

######################### MAIN ############################

echo
echo "RUNNING ${SCRIPT_NAME} ..."

echo
echo "  Scripts to be executed:"
echo "    refindex.sh"

echo
echo "  Submitting execution job..."

echo "  SUBMITTING refindex.sh"

REFINDEX=$(
    sbatch \
        --parsable \
        --cpus-per-task="${BWA_CPUS}" \
        --output="${LOG_DIR}/refindex.%j.log" \
        "${MODULES_DIR}/refindex.sh"
) || fail "  Failed to submit refindex.sh"

echo "  refindex.sh SUBMITTED"

echo "  Pipeline SUBMITTED"
echo "  Job ID: ${REFINDEX}"
echo "${SCRIPT_NAME} COMPLETE"
echo