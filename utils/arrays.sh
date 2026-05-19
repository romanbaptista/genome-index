#!/bin/bash

# PREFLIGHT_ARRAY:
# Ordered list of preflight scripts executed during pipeline validation.
# This array defines all preflight checks required to safely run the pipeline.
# Each script is sourced sequentially by preflight.sh before any pipeline
# modules are executed.
#
# Define preflight array (all preflight scripts, order is significant)
PREFLIGHT_ARRAY=(
    "preflight_input.sh"
    "preflight_variables.sh"
    "preflight_scripts.sh"
    "preflight_commands.sh"
    "preflight_bwa.sh"
    "preflight_samtools.sh"
)

# SCRIPT_ARRAY:
# Ordered list of module scripts that comprise the pipeline execution layer.
#
# Scope:
#   - Used by preflight_scripts.sh to validate script existence and integrity.
#   - Defines the set of valid execution modules that may be dispatched by pipeline.sh.
#
# Design note:
#   This array describes pipeline structure, not execution order.
SCRIPT_ARRAY=(
    "refindex.sh"
)

# EXPORT_ARRAY:
# Canonical list of pipeline-owned variables that define the execution ABI.
#
# Scope:
#   - Acts as the single source of truth for environment variables that must be
#     inherited across process boundaries (e.g. into SLURM jobs).
#   - Consumed by run_pipeline.sh to:
#       1. export variables into the shell environment
#       2. construct SBATCH_EXPORTS for controlled propagation
#   - Consumed by downstream scripts to validate required execution context.
#
# Guarantees:
#   - All variables listed here are defined exactly once in run_pipeline.sh.
#   - Only pipeline-owned variables appear here (never SLURM-injected variables).
#   - Every non-SLURM variable used in downstream scripts must appear here.
#
# Design principles:
#   - Defines the execution ABI (application binary interface), not logical dependencies.
#   - Immutable after initialization — must never be modified in downstream scripts.
#   - Structured (array) representation is canonical; SBATCH_EXPORTS is a derived snapshot.
# Note:
#   Variables used exclusively within the preflight layer (e.g. ENV_NAME, YAML_FILE)
#   are intentionally excluded from EXPORT_ARRAY and defined within their owning scripts.
EXPORT_ARRAY=(
    REF_FASTA
    BWA_CPUS
    PIPELINE_DIR
    MODULES_DIR
    PREFLIGHT_DIR
    UTILS_DIR
    LOG_DIR
)

# COMMAND_ARRAY:
# Canonical list of external commands required for execution of
# preflight, orchestration, and module layers.
#
# Scope:
#   - Validated by preflight_commands.sh.
#   - Includes only framework-level commands used by:
#       - run_pipeline.sh
#       - preflight scripts
#       - pipeline.sh
#       - execution modules
#
# Notes:
#   - Tool-specific binaries (e.g. bbduk, java, trimmomatic) are intentionally excluded
#     and validated by dedicated tool preflight scripts.
COMMAND_ARRAY=(
    bwa
    samtools
    source
    sbatch
    tee
    grep
    module
    dirname
    basename
)

# VARIABLE_ARRAY:
# List of required user-defined configuration variables.
#
# Scope:
#   - Validated by preflight_variables.sh.
#   - Variables must be defined and non-empty in config.sh.
#
# Design note:
#   These represent user inputs, not runtime ABI — but are included in EXPORT_ARRAY
#   so they are available in downstream execution contexts.
VARIABLE_ARRAY=(
    REF_FASTA
    BWA_CPUS
)


# BWA_MODULE:
# Cluster-specific module providing the bwa executable.
#
# Value:
#   Full module name required by the HPC environment (e.g. apps/bwa-0.7.10.tcl).
#
# Operation:
#   - Loaded during preflight using 'module load'.
#   - Makes the bwa command available in PATH for downstream execution.
#   - Must provide a version supporting 'bwa mem'.
#
# Notes:
#   - This value is cluster-dependent and may need updating when migrating
#     the pipeline to a different HPC environment.
#   - Treated as an infrastructure variable, not user-configurable input.
#
# Example:
#   BWA_MODULE="apps/bwa-0.7.10.tcl"
BWA_MODULE="apps/bwa-0.7.10.tcl"


# SAMTOOLS_MODULE:
# Cluster-specific module providing the samtools executable.
#
# Value:
#   Full module name required by the HPC environment (e.g. apps/samtools-1.9.tcl).
#
# Operation:
#   - Loaded during preflight using 'module load'.
#   - Makes the samtools command available in PATH for downstream execution.
#   - Must provide a version supporting 'samtools faidx'.
#
# Notes:
#   - This value is cluster-dependent and may need updating when migrating
#     the pipeline to a different HPC environment.
#   - Treated as an infrastructure variable, not user-configurable input.
#
# Example:
#   SAMTOOLS_MODULE="apps/samtools-1.9.tcl"
SAMTOOLS_MODULE="apps/samtools-1.9.tcl"