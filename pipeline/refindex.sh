#!/bin/bash
set -euo pipefail

######################### GUARDS #########################

GUARD_ARRAY=(
    FUNCTIONS_DIR
    REF_FASTA
    SLURM_CPUS_PER_TASK
    BWA_MODULE
    SAMTOOLS_MODULE
)

for var in "${GUARD_ARRAY[@]}"; do
    : "${!var:?${var} not set or empty}"
done

######################### SETUP ##########################

# Define script name
SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"

######################### SOURCE #########################

source /etc/profile.d/modules.sh
source "${FUNCTIONS_DIR}/functions_base.sh"

######################### MODULES ########################

module load "${BWA_MODULE}"
module load "${SAMTOOLS_MODULE}"

######################### MAIN ###########################

echo
echo "RUNNING ${SCRIPT_NAME} ..."

echo "  Generating bwa mem index..."

bwa index -t "${SLURM_CPUS_PER_TASK}" "${REF_FASTA}"

echo "  bwa indexing complete"
echo "  Generating samtools faidx index..."

samtools faidx "${REF_FASTA}"

echo "  samtools faidx indexing complete"
echo "${SCRIPT_NAME} COMPLETE"