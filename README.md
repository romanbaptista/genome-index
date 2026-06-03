# `genome-index`

# Overview
This repository contains the `genome-index` pipeline — a modular, HPC‑compatible workflow for:

> Deterministically generating BWA and samtools index files for a reference genome FASTA using a fully contract‑driven, SLURM‑native execution model.

The pipeline is designed for execution in HPC environments and provides:
- Deterministic, single-pass reference indexing using `bwa` and `samtools`
- Strict fail‑fast validation prior to any job submission
- Explicit execution ABI for safe variable propagation across SLURM boundaries
- Clean separation between validation, orchestration, and execution layers
- Minimal, atomic execution model (one reference → one job)
- Fully reproducible and portable behaviour across HPC systems

Unlike sample-based pipelines, genome-index operates on a single reference genome and produces a fully indexed dataset required for downstream alignment workflows.

Internally, the pipeline adheres to a strict contract-driven architecture, enforcing separation between:
- configuration
- declarative contract definition
- validation
- execution

This guarantees reproducibility, portability, and fail‑fast behaviour across HPC environments.

# Repository Structure

```text
genome-index/
├── README.md                     # Top-level overview (this file)
├── config.sh                     # User configuration (reference + resources)
├── genome-index.sh               # Entry point (logging + preflight + submission)
│
├── arrays/                       # Declarative pipeline contracts (ABI + ordering)
│   ├── array_preflight.sh
│   ├── array_pipeline.sh
│   ├── array_variables.sh
│   ├── array_binaries.sh
│   └── array_exports.sh
│
├── utils/                        # Static variable definitions (no logic)
│   ├── utils_paths.sh
│   ├── utils_bwa.sh
│   └── utils_samtools.sh
│
├── functions/                    # Atomic helper functions
│   └── functions_base.sh
│
├── preflight/                    # Validation + environment setup
│   ├── preflight.sh
│   ├── preflight_variables.sh
│   ├── preflight_input.sh
│   ├── preflight_binaries.sh
│   ├── preflight_exports.sh
│   ├── preflight_pipeline.sh
│   ├── preflight_bwa.sh
│   └── preflight_samtools.sh
│
├── pipeline/                     # Execution layer
│   ├── pipeline.sh               # SLURM orchestrator
│   └── refindex.sh               # Reference indexing module
│
└── logs/                         # Centralised logs (created at runtime)
```

# Workflow
At a high level, the pipeline executes in three phases:

## Preflight validation
The preflight layer performs strict fail-fast validation before any SLURM job is submitted:
- Verifies all required system binaries are available
- Confirms required configuration variables are defined and non-empty
- Validates the reference FASTA:
  - exists
  - contains data
  - has a valid extension (`.fa`, `.fasta`, `.fna`)
- Ensures pipeline scripts exist and are executable
- Loads and validates bwa and samtools via the HPC module system
- Constructs the execution ABI (`EXPORT_ARRAY`)
- Generates `SBATCH_EXPORTS` for SLURM environment propagation

This guarantees that all execution invariants are satisfied before scheduling any compute work.

## Pipeline orchestration
The entrypoint (`genome-index.sh`) submits a SLURM orchestration job (`pipeline.sh`), which:
- Logs execution to a centralised log file
- Consumes the immutable execution ABI (`SBATCH_EXPORTS`)
- Submits the reference indexing module as a single SLURM job
- Passes CPU allocation explicitly via `--cpus-per-task`
- Captures the resulting job ID for traceability

## Execution module
- `refindex.sh`
- Loads required HPC modules (`bwa`, `samtools`)
- Uses SLURM-provided CPU resources (`SLURM_CPUS_PER_TASK`)
- Runs:

```text
bwa index → samtools faidx
```

- Generates index files alongside the reference FASTA
- Performs no validation (assumes preflight guarantees)
- Executes as a single atomic job

# Execution Model
The pipeline enforces strict execution boundaries:

```text
login node
  → preflight (validation + ABI construction)
    → SLURM job (pipeline.sh)
      → SLURM job (refindex.sh)
```

### Key guarantees:
- No implicit environment state crosses boundaries
- All variables are passed explicitly via `SBATCH_EXPORTS`
- Tool environments are reconstructed in SLURM jobs
- Execution modules rely only on exported variables and SLURM context
- Preflight guarantees eliminate the need for runtime validation

# Configuration
All user-defined parameters are specified in `config.sh`.

At minimum:
```bash
REF_FASTA="/path/to/reference.fa"
BWA_CPUS=4
```

# Configuration Variables

| Variable   | Description |
|----------|------------|
| REF_FASTA | Path to reference genome FASTA file to be indexed |
| BWA_CPUS | Number of CPU threads allocated to indexing |

# Usage
From the pipeline root directory:

```bash
bash genome-index.sh
```

This will:
- Execute full preflight validation
- Validate and load required tool modules
- Construct the execution ABI
- Submit SLURM job(s)
- Generate reference index files

# Outputs
No dedicated output directory is created.

Instead, index files are generated alongside the reference FASTA:

```text
reference.fa
reference.fa.bwt
reference.fa.pac
reference.fa.ann
reference.fa.amb
reference.fa.sa
reference.fa.fai
```

These files together represent a fully indexed reference, ready for use in alignment pipelines.

# Architecture Summary

| Layer | Responsibility |
|------|----------------|
| `config.sh` | User-defined configuration |
| `arrays/` | Declarative pipeline contract and ABI |
| `utils/` | Static variable definitions (tool + paths) |
| `functions/` | Atomic helper functions |
| `preflight/` | Validation and environment setup |
| `pipeline/` | SLURM orchestration |
| modules | Execution (reference indexing) |

# Further Documentation
For detailed documentation on individual components:
- `arrays/README.md` — contract layer and ABI design
- `preflight/README.md` — validation logic and guarantees
- `pipeline/README.md` — orchestration and execution model
- `utils/README.md` — static variables and tool parameters
- `functions/README.md` — helper functions and validation primitives

# Design Principles
This pipeline enforces:
- Contract-driven design
- Fail-fast validation
- Explicit execution boundaries
- Minimal and explicit execution ABI
- Deterministic execution
- Clean separation of concerns
- Reproducible HPC workflows

# Citation
If you use this pipeline in published work, please cite:
> Baptista, R. _genome-index: A contract-driven HPC pipeline for reference genome indexing_.
> GitHub repository: https://github.com/romanbaptista/genome-index