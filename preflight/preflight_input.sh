#!/bin/bash
set -euo pipefail

######################### GUARDS ##########################

: "${REF_FASTA:?REF_FASTA not set (check config.sh)}"

######################### SETUP ##########################

# Define script name
SCRIPT_NAME=$(basename "${BASH_SOURCE[0]}" .sh)

######################### MAIN ############################

echo "  RUNNING ${SCRIPT_NAME} ..."
echo "  Checking reference genome FASTA: ${REF_FASTA}"

# Check reference genome FASTA
check_file "${REF_FASTA}" || fail "  Please provide a REF_FASTA file in config.sh that exists"
check_file_data "${REF_FASTA}" || fail "  Please provide a REF_FASTA file in config.sh that contains data"

echo "  Checking for acceptable FASTA filetypes..."

# Check for .fa/.fasta/.fna file
case "${REF_FASTA,,}" in
  *.fa|*.fasta|*.fna) ;;
  *) fail "  REF_FASTA must have extension .fa, .fasta, or .fna" ;;
esac

echo "  Input FASTA confirmed: ${REF_FASTA}"
echo "  ${SCRIPT_NAME} COMPLETE"