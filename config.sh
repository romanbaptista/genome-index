#!/bin/bash

################################# INPUT #################################


# REF_FASTA:
# Absolute or relative path to the reference genome FASTA file to be indexed.
#
# This file MUST exist, MUST be readable, and represents the reference
# against which downstream pipelines (e.g. alignment) will operate.
#
# The FASTA will NOT be modified; instead, index files required for
# `bwa mem` and `samtools` will be generated alongside this file,
# producing a fully indexed reference dataset.
#
# Supported extensions include .fa, .fasta, .fna.
# This value is consumed by downstream execution modules (refindex.sh).
REF_FASTA=""

######################### REFINDEX.SH ###################################

# BWA_CPUS:
# Number of CPU threads allocated to the `bwa index` step.
#
# This value controls the level of parallelism used during reference
# indexing and is passed to the execution module via the SLURM
# allocation (e.g. --cpus-per-task).
#
# Increasing this value may improve indexing speed for large genomes,
# but has no effect on correctness and has minimal impact for small
# references such as bacterial genomes.
#
# This value is passed to the scheduler via pipeline.sh and
# consumed indirectly by refindex.sh via SLURM_CPUS_PER_TASK.
BWA_CPUS=4