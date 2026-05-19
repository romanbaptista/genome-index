# `modules`

This directory contains the execution layer for the `ref-index` pipeline.

Each module is responsible for a clearly defined execution role and operates under a strict, preflight‑validated contract designed for HPC environments, where all compute‑intensive work is delegated to the scheduler.

Modules are coordinated by `modules/pipeline.sh`, which is invoked by `run_pipeline.sh` only after all preflight checks have completed successfully.

Unlike sample-based pipelines, `ref-index` operates on a single global input (a reference FASTA) and performs a single atomic operation.

# Design Contract
All modules in this directory adhere to the following principles:
- Single responsibility per script
- Explicit, absolute paths for all inputs and outputs
- Strong separation between validation and execution
- Deterministic execution model
- No reliance on implicit working directories
- No reliance on undeclared global state
- No duplication of preflight validation logic
- Assumption that all preflight invariants have already been enforced
- Strict consumption of the execution ABI (`EXPORT_ARRAY` + SLURM variables)
- Atomic mutation of shared reference state

Modules do not perform input validation, tool installation, or configuration checks.

All such guarantees are established by the preflight layer and enforced via guarded environment variables.

# Execution Model
`ref-index` is a scheduler‑backed pipeline:
- Orchestration logic runs on the login node
- Execution modules run as SLURM jobs on compute nodes
- Execution behaviour is controlled via an explicit environment contract

The execution flow is:

```text
run_pipeline.sh
  └─ pipeline.sh
       └─ refindex.sh
```

Exactly one execution module is dispatched per pipeline run.
All SLURM submissions occur only after successful preflight validation.

# Module Overview
## `pipeline.sh`
Internal orchestrator for the `ref-index` pipeline.

### Role
- `pipeline.sh` is responsible for submitting the reference indexing job to the SLURM scheduler.
- It does not perform any indexing itself and is not intended to be executed directly by end users.

### Workflow
- Runs as a SLURM job submitted by `run_pipeline.sh`
- Guards all required variables defined in the execution ABI
- Assumes all preflight checks have succeeded
- Submits exactly one execution module (`refindex.sh`)
- Passes resource requests (e.g. CPU allocation) to SLURM
- Captures the submitted job ID for diagnostics

`pipeline.sh` does not perform any data processing or tool execution.

Guarantees
- Deterministic orchestration
- No mutation of the execution ABI
- Single job submission per pipeline run
- No reference data manipulation
- No duplication of preflight logic

## `refindex.sh`
Execution module for reference genome indexing.

### Role
Performs indexing of a reference FASTA file using:
- `bwa index` (for alignment)
- `samtools faidx` (for FASTA random access)

This module is the only component responsible for mutating the reference into a fully indexed state.

### Inputs
- `REF_FASTA`: Reference genome FASTA file
- `SLURM_CPUS_PER_TASK`: SLURM‑injected variable, execution ABI (`EXPORT_ARRAY`) from `run_pipeline.sh`

### Workflow
- Guards all required variables at entry
- Assumes preflight validation has completed successfully
- Loads the module environment for compute nodes
- Executes reference indexing sequentially:

```text
bwa index → samtools faidx
```

Writes index files alongside the reference FASTA

### Outputs
No dedicated output directory is used.

All index files are written directly alongside the input FASTA:

```text
reference.fa
reference.fa.bwt
reference.fa.pac
reference.fa.ann
reference.fa.amb
reference.fa.sa
reference.fa.fai
```

# Guarantees
- Single atomic execution unit
- No partial or parallel index creation
- Deterministic outputs for a given reference
- No modification of the FASTA sequence data
- No reliance on implicit working directories
- Fully aligned with SLURM resource allocation
- Safe reuse of indexed reference across downstream pipelines

# Design Notes
- Index files are treated as part of the reference object, not pipeline outputs
- The pipeline performs a global, shared data mutation and must therefore remain atomic
- Splitting indexing steps across multiple SLURM jobs is explicitly avoided
- Execution modules do not perform validation, tool installation, or configuration parsing
- All modules rely exclusively on the execution ABI and scheduler-provided variables

# Notes
- All modules assume preflight validation has completed successfully
- No module installs software or configures the runtime environment
- All filesystem paths are explicit and derived from the execution ABI
- All required variables are guarded at entry
- No module requires interactive input
- The pipeline is safe to re-run; indexing steps are deterministic and idempotent
- Downstream pipelines (e.g. alignment) may safely consume the indexed reference