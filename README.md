# `ref-index`

# Overview
This repository contains the `ref-index` pipeline — a modular, HPC‑compatible workflow for:
> Deterministic preparation of reference genome FASTA files for downstream alignment pipelines via generation of required index files.

The pipeline exists to ensure that reference indexing is:
- Explicit (never implicit within alignment workflows)
- Reproducible across HPC environments
- Executed once per reference, not per dataset
- Guaranteed via a strict preflight validation layer

The pipeline is designed specifically for HPC environments and supports:
- Explicit execution contracts for deterministic behaviour across SLURM boundaries
- Strict separation of configuration, validation, orchestration, and execution layers
- Guaranteed presence and correctness of reference index files before downstream use
- A single atomic execution model ensuring reference integrity
- Canonical pipeline structure defined via shared arrays and enforced contracts

Unlike sample-driven pipelines, `ref-index` operates on a single reference genome and produces reusable, global artefacts.

# Repository Structure

```text
ref-index/
├── README.md                               # Top-level overview (this file)
├── config.sh                               # User configuration (reference + resources)
├── run_pipeline.sh                         # Entry point (login-node orchestration)
├── utils/                                  # Shared utilities and canonical definitions
│   ├── arrays.sh                           # Source of truth for pipeline structure and ABI
│   ├── functions_base.sh                   # General-purpose helper functions
│   ├── functions_bwa.sh                    # bwa validation helpers
│   └── functions_samtools.sh               # samtools validation helpers
├── preflight/                              # Preflight validation layer
│   ├── preflight.sh
│   ├── preflight_input.sh
│   ├── preflight_variables.sh
│   ├── preflight_scripts.sh
│   ├── preflight_commands.sh
│   ├── preflight_bwa.sh
│   └── preflight_samtools.sh
└── modules/                                # Execution layer
    ├── pipeline.sh                         # SLURM orchestrator
    └── refindex.sh                         # Reference indexing module
```

# Workflow
At a high level, the pipeline proceeds as follows:

### Preflight validation
The preflight layer executes entirely on the login node and:
- Verifies all required framework-level commands are available
- Confirms all required user configuration variables are set and non-empty
- Validates that the reference FASTA exists and is non-empty
- Ensures the FASTA has an acceptable extension (`.fa`, `.fasta`, `.fna`)
- Confirms module scripts exist, contain data, and are executable
- Loads cluster modules for bwa and `samtools` explicitly
- Validates that `bwa mem` and `samtools faidx` functionality is available

All validation is authoritative and occurs before any SLURM jobs are submitted.

### Pipeline orchestration
- The pipeline is launched via run_pipeline.sh from the login node
- A strict execution ABI is constructed via `EXPORT_ARRAY`
- Only explicitly declared variables are propagated to SLURM jobs via `--export`
- A single orchestrator job (`modules/pipeline.sh`) is submitted
- The orchestrator dispatches a single atomic indexing job

### Reference indexing execution
The execution module (refindex.sh) runs under SLURM and:
- Uses only explicitly exported variables and SLURM-provided resources
- Builds a BWA index using `bwa index`
- Builds a FASTA index using `samtools faidx`
- Writes all index files alongside the reference FASTA
- Produces no other outputs or side effects

Execution modules assume all preflight guarantees are satisfied and perform no validation.

# Configuration
All user-defined parameters are specified in `config.sh`.

Configuration variables
| Variable   | Description |
|------------|-------------|
| `REF_FASTA`  | Absolute or relative path to the reference genome FASTA file to be indexed |
| `BWA_CPUS`   | Number of CPU threads allocated to the indexing job |


# Required Input
The pipeline operates on a single reference FASTA file:

```text
/path/to/reference.fa
```

The file must:
- Exist and be readable
- Contain sequence data
- Use an accepted FASTA extension (`.fa`, `.fasta`, `.fna`)

# Usage
Navigate to the root of the repository and run:

```bash
run_pipeline.sh
```

This will:
- Perform all preflight validation checks
- Load required cluster modules
- Submit the indexing workflow via SLURM

# Outputs
The pipeline does not produce outputs in a dedicated directory.

Instead, it generates index files directly alongside the reference FASTA:

```text
reference.fa
reference.fa.bwt
reference.fa.pac
reference.fa.ann
reference.fa.amb
reference.fa.sa
reference.fa.fai
```

These files collectively define a fully indexed reference suitable for alignment workflows.

# Design Notes
- Index files are treated as part of the reference object, not pipeline outputs
- Indexing is performed exactly once per reference
- Downstream pipelines (e.g. alignment) must assume indexes exist and must not create them
- Execution is atomic — the reference transitions from “unindexed” to “fully indexed”

# Further Documentation
For detailed documentation on individual components, see:
- `preflight/README.md` — validation guarantees and execution ordering
- `modules/README.md` — execution model and contract assumptions
- `utils/README.md` — shared utilities and execution ABI

# Citation
If you use this pipeline in published work, please cite:

> Baptista, R. _ref-index: A contract-driven HPC pipeline for reference genome indexing_.
> GitHub repository: https://github.com/romanbaptista/ref-index

Optionally include the commit hash or release tag used for analysis.
