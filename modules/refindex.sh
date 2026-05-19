#!/bin/bash
#SBATCH --job-name=refindex
set -euo pipefail

######################### GUARDS ##########################

# Required variables inherited via EXPORT_ARRAY and SLUR
GUARD_ARRAY=(
    REF_FASTA
    SLURM_CPUS_PER_TASK
)

for var in "${GUARD_ARRAY[@]}"; do
    : "${!var:?${var} not set or not exported (check SLURM allocation or EXPORT_ARRAY)}"
done

######################### SETUP ###########################

SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}" .sh)"

######################### SOURCE ##########################

# Enable module commands for batch jobs (if SLURM)
source /etc/profile.d/modules.sh

######################### MAIN ############################

echo
echo "RUNNING ${SCRIPT_NAME} ..."
echo
echo "  Info:"
echo "    Reference FASTA:    ${REF_FASTA}"
echo "    BWA CPUs:           ${SLURM_CPUS_PER_TASK}"

echo "  Generating bwa mem index..."
# Run bwa index
bwa index -t "${SLURM_CPUS_PER_TASK}" "${REF_FASTA}"
echo "  bwa indexing complete"

echo "  Generating samtools faidx index..."
# Run samtools faidx
samtools faidx "${REF_FASTA}"
echo "  samtools faidx indexing complete"

echo
echo "${SCRIPT_NAME} COMPLETE"
echo