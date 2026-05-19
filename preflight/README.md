# `preflight`

This directory contains the preflight validation layer for the `ref-index` pipeline.

Preflight scripts are responsible for all validation and environment checks required to safely execute the pipeline on an HPC system before any SLURM jobs are submitted.

No pipeline modules are executed unless all preflight checks succeed.

All preflight scripts are sourced and executed by `run_pipeline.sh` on the login node, ensuring that pipeline execution begins only after the environment, configuration, and reference inputs are fully validated.

# Design Contract
All preflight scripts adhere to the following principles:
- Fail‑fast validation before any pipeline execution
- No side effects beyond controlled environment setup (e.g. module loading)
- Clear, actionable error messages on failure
- Deterministic behaviour with explicit ordering
- Validation only — no execution or reference mutation logic
- Centralised enforcement of pipeline invariants
- Strict use of canonical arrays (`PREFLIGHT_ARRAY`, `COMMAND_ARRAY`, `VARIABLE_ARRAY`)

Once preflight validation completes successfully, downstream scripts may assume:
- All required configuration variables are valid and non‑empty
- The reference FASTA exists, is non-empty, and correctly formatted
- All required commands and tools are available and usable
- Required module scripts exist and are executable
- HPC modules for `bwa` and `samtools` are loaded and functional
- Execution modules can safely run without any further validation

# Responsibilities of Preflight
The preflight layer ensures that:
- Required user configuration variables are defined and valid
- The reference FASTA exists, contains data, and has a valid extension
- Pipeline module scripts exist, contain code, and are executable
- Required external commands are available in the system `PATH`
- HPC modules for bwa and samtools are loaded explicitly
- Required tool functionality (`bwa mem`, `samtools faidx`) is present

This prevents late-stage failures, wasted cluster resources, and incorrect or partial reference indexing.

# Preflight Script Overview
The set and execution order of all preflight scripts is centrally defined in:

```text
utils/arrays.sh  → PREFLIGHT_ARRAY
```

`preflight/preflight.sh` sources and executes each script listed in `PREFLIGHT_ARRAY`.

## Current preflight order

```text
preflight_input.sh
preflight_variables.sh
preflight_scripts.sh
preflight_commands.sh
preflight_bwa.sh
preflight_samtools.sh
```

All scripts are executed sequentially. Any failure aborts the entire pipeline.

## `preflight_input.sh`
Validates the reference input.

### Responsibilities
- Confirms `REF_FASTA` is defined and non-empty
- Verifies that the FASTA file exists
- Confirms the FASTA contains data (non-zero file size)
- Ensures the file has an accepted extension (`.fa`, `.fasta`, `.fna`)

This script enforces the reference input contract, ensuring a valid genome is provided before indexing begins.

## `preflight_variables.sh`
Validates required user‑defined configuration variables.

### Responsibilities
- Confirms all variables listed in `VARIABLE_ARRAY` are defined and non-empty

These variables originate from config.sh and are propagated via the execution ABI.

## `preflight_scripts.sh`
Validates pipeline module integrity.

### Responsibilities
- Confirms all scripts listed in `SCRIPT_ARRAY` exist under `modules/`
- Verifies that each script is non‑empty
- Ensures each script is executable (or makes it executable if possible)
- Confirms presence and integrity of `modules/pipeline.sh`

This prevents execution of incomplete, missing, or non-runnable module code.

## `preflight_commands.sh`
Validates required framework‑level external commands.

### Responsibilities
- Confirms availability of all commands listed in `COMMAND_ARRAY`
- Uses strict `PATH‑based` validation

Commands validated include:
- SLURM interface (`sbatch`)
- Core shell and filesystem utilities
- Logging and text-processing tools
- Module system commands

Tool‑specific binaries (`bwa`, `samtools`) are also included, but their functionality is verified separately.

## `preflight_bwa.sh`
Validates and prepares the `bwa` environment.

### Responsibilities
- Loads the cluster-specific module defined by `BWA_MODULE`
- Verifies the `bwa` executable is available in `PATH`
- Confirms that `bwa` supports the `mem` subcommand

This script ensures that the alignment indexing toolchain is available and functional.

## `preflight_samtools.sh`
Validates and prepares the `samtools` environment.

### Responsibilities
- Loads the cluster-specific module defined by `SAMTOOLS_MODULE`
- Verifies the `samtools` executable is available in `PATH`
- Confirms that `samtools` supports the `faidx` command

This script ensures that FASTA indexing functionality is available and usable.

# Execution Model
All preflight scripts are:
- Executed on the login node
- Sourced into a single shell for shared context
- Run in a strictly defined order
- Terminated immediately on failure

The pipeline does not proceed unless all preflight scripts complete successfully.

# Invariants Guaranteed After Preflight
After successful preflight validation, downstream pipeline stages may assume:
- `REF_FASTA` exists, is readable, and contains valid sequence data
- Reference file extension is valid
- Required configuration variables are defined and correct
- All module scripts are present, non-empty, and executable
- Required framework-level commands are available
- `bwa` module is loaded and supports `bwa mem`
- `samtools` module is loaded and supports `samtools faidx`
- Execution ABI (`EXPORT_ARRAY`) is complete and correct

These guarantees allow execution modules to operate without performing any validation.

# Notes
- Preflight scripts are not intended to be run directly by end users
- No reference indexing occurs during preflight
- All validation logic is centralised in this directory
- Module scripts do not repeat validation checks
- Arrays (`PREFLIGHT_ARRAY`, `COMMAND_ARRAY`, `VARIABLE_ARRAY`) define the canonical validation surface
- HPC module loading is explicit and deterministic
- Any modification to configuration, reference input, or pipeline structure requires rerunning preflight