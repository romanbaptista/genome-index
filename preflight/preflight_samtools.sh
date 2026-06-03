#!/bin/bash

######################### GUARDS #########################

GUARD_ARRAY=(
    UTILS_DIR
    SAMTOOLS_MODULE
)

for var in "${GUARD_ARRAY[@]}"; do
    variable_check_nonempty "${var}" || fail_message "Variable is empty or not defined: ${var}"
done

######################### SETUP ##########################

# Define script name
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"
# Define toolname
TOOLNAME="samtools"

######################### SOURCE #########################

source "${UTILS_DIR}/utils_${TOOLNAME}.sh"

######################### MAIN ###########################

echo
echo "RUNNING ${SCRIPT_NAME} ..."
echo "  Checking ${TOOLNAME} functionality..."

module load "${SAMTOOLS_MODULE}" || fail_message "Failed to load module: ${SAMTOOLS_MODULE}"
tool_check_binary ${TOOLNAME} || fail_message "Binary not found: ${TOOLNAME}"
tool_check_subcommand ${TOOLNAME} faidx || fail_message "Subcommand not found: ${TOOLNAME} faidx"

echo "  ${TOOLNAME} loaded and functionality confirmed"
echo "${SCRIPT_NAME} COMPLETE"