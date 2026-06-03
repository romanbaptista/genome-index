# `pipeline`

# Overview
The `pipeline/` directory contains the execution layer of the `genome-index` pipeline.

| File | Responsibility |
|------|----------------|
| `pipeline.sh` | Orchestrates SLURM job submission |
| `refindex.sh` | Performs reference genome indexing (`bwa` + `samtools`) |

These scripts implement the reference indexing workflow, operating on a fully validated environment constructed by the preflight layer.

All execution within this directory assumes that:
- all required variables are defined and exported via the execution ABI
- all required tools are available via the HPC module system
- the reference FASTA has been validated
- pipeline scripts are present and executable
- SLURM execution environment is correctly initialised

No validation or environment construction logic is duplicated in this layer.

# Module Naming Convention
Module scripts follow the pattern:

```text
<function>.sh
```

In this pipeline:

```text
refindex.sh → reference genome indexing (bwa + samtools)
```

This pipeline implements a single execution module rather than multiple selectable modules or stages.

This convention provides:
- a clear mapping between pipeline purpose and execution
- consistent naming across pipelines
- improved readability in logs and job submission

# Design Contract
All scripts in this directory adhere to the following principles:
- single responsibility per script
- execution-only (no validation beyond guard checks)
- explicit input paths
- deterministic behaviour
- no reliance on implicit working directories
- no reliance on undeclared global state
- compatibility with SLURM execution boundaries

Modules assume that all preflight invariants have already been enforced.

# Execution Model
The execution layer is orchestrated by `pipeline.sh`.

This script:
- runs as a SLURM job submitted after preflight
- consumes a fully validated environment via `SBATCH_EXPORTS`
- submits the reference indexing module (`refindex.sh`) via SLURM
- passes CPU allocation from configuration (`BWA_CPUS`)
- captures the submitted job ID

Execution behaviour is defined by:
- explicit SLURM job submission
- minimal orchestration logic
- deterministic resource allocation
- a single execution module

| Component | Role |
|----------|------|
| `pipeline.sh` | Submits execution module via SLURM |
| `refindex.sh` | Executes reference indexing |

# `pipeline.sh`

### Role
- SLURM orchestration script for execution
- Performs no data processing

### Responsibilities
- configures pipeline-level logging using tee
- validates required execution variables via guard checks
- reads module definitions from `PIPELINE_ARRAY`
- submits `refindex.sh` via `sbatch`
- propagates the execution ABI via `SBATCH_EXPORTS`
- applies CPU allocation via `--cpus-per-task`
- captures job ID using `--parsable`

### Guarantees
- deterministic orchestration
- correct propagation of execution ABI
- no duplication of preflight validation
- strict separation between orchestration and execution

# Module Overview
The pipeline contains a single execution module:

## `refindex.sh`
### Role
Performs reference genome indexing using `bwa` and `samtools`.

### Inputs
```text
REF_FASTA
SLURM_CPUS_PER_TASK
BWA_MODULE
SAMTOOLS_MODULE
FUNCTIONS_DIR
```

### Workflow
- initialises module system (`modules.sh`)
- loads required modules (`bwa`, `samtools`)
- executes:

```text
bwa index → samtools faidx
```

writes all index files alongside the reference FASTA

Outputs
```text
reference.fa
reference.fa.bwt
reference.fa.pac
reference.fa.ann
reference.fa.amb
reference.fa.sa
reference.fa.fai
```

### Guarantees
- single atomic execution unit
- deterministic outputs
- no modification of original FASTA contents
- no reliance on implicit environment state
- strict use of SLURM-provided resources
- no validation or setup logic

# Execution Boundary Considerations
This pipeline operates across strict execution boundaries:

```text
preflight (login node)
  → sbatch pipeline.sh
    → sbatch refindex.sh
```

### Key principles
- each SLURM job runs in a new shell
- environment state is never implicitly shared
- all required variables are passed explicitly
- module environment must be reconstructed in execution modules

This is enforced through:
```text
EXPORT_ARRAY → defines execution ABI
SBATCH_EXPORTS → injects variables into SLURM jobs
```

### Execution modules:
- rely only on exported variables and SLURM environment
- do not source configuration or utility scripts
- perform minimal guard-based validation

# Logging Model
The pipeline implements structured logging:
```text
pipeline.sh → orchestration log (logs/pipeline.log)
refindex.sh → SLURM job-level log (logs/refindex.<jobid>.log)
```

This ensures:
- traceable execution
- reproducible debugging
- clear separation between orchestration and execution logs

# Key Rules
- do not include validation logic in modules
- do not install tools during execution
- do not modify global configuration
- always use explicit paths
- maintain atomic execution behaviour
- maintain strict separation between orchestration and execution
- never rely on implicit environment state across SLURM boundaries


# Summary
The `pipeline/` directory implements the execution phase of the `genome-index` pipeline.

It provides:
- a SLURM-based orchestration layer
- a single, deterministic execution module
- atomic reference genome indexing
- explicit and minimal execution ABI propagation

This design ensures that runtime behaviour is:
- reproducible
- portable across HPC environments
- deterministic
- easy to maintain and extend