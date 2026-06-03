#!/bin/bash

######################### GUARDS #########################

GUARD_ARRAY=(
    REF_FASTA
)

for var in "${GUARD_ARRAY[@]}"; do
    variable_check_nonempty "${var}" || fail_message "Variable is empty or not defined: ${var}"
done

######################### SETUP ##########################

# Define script name
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"

######################### MAIN ###########################

echo
echo "RUNNING ${SCRIPT_NAME} ..."
echo "  Confirming reference FASTA file..."

file_check_exists "${REF_FASTA}" || fail_message "Reference FASTA file not found"
file_check_nonempty "${REF_FASTA}" || fail_message "Reference FASTA file is empty"

echo "  Reference FASTA file confirmed"
echo "  Validating reference FASTA filetype..."

# Check for .fa/.fasta/.fna file
case "${REF_FASTA,,}" in
  *.fa|*.fasta|*.fna) ;;
  *) fail_message "REF_FASTA must have extension .fa, .fasta, or .fna" ;;
esac

echo "  Valid filetype confirmed"
echo "${SCRIPT_NAME} COMPLETE"