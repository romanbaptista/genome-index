# `utils`

# Overview
The `utils/` directory contains all static variable definitions used throughout the `genome-index` pipeline.

These scripts define:
- core directory paths
- cluster-specific tool module identifiers
- static, pipeline-wide configuration parameters

Importantly, `utils/` is a pure definition layer — it contains no logic, validation, or execution.

# Design Principles
The `utils/` layer follows strict design rules:
- Definitions only — no functions or control flow
- No validation — all checks occur in the preflight layer
- No side effects — sourcing only sets variables
- Centralised variable ownership — each variable is defined exactly once
- Deterministic behaviour — no runtime decisions or dynamic modification

These principles enforce strict separation between:
- what is defined (`utils/`)
- what is validated (`preflight/`)
- what is executed (`pipeline/` and modules)


# Role in the Pipeline
The `utils/` layer acts as the source of truth for static, shared variables, particularly:
- directory structure definitions
- cluster-specific tool module names
- pipeline-wide constants required during validation and execution

| Aspect | Description |
|--------|------------|
| Purpose | Static variable definitions |
| Contains logic? | No |
| Performs validation? | No |
| Consumed by | Preflight and execution layers |
| Scope | Paths and tool module identifiers |

Variables defined in `utils/` are:
- consumed by preflight scripts for validation and environment construction
- propagated across execution boundaries via the ABI when required
- used by execution modules to reconstruct runtime environments

This ensures all shared parameters are:
- defined once
- validated centrally
- used consistently across all pipeline layers

# File Overview
The directory is organised into:
- a shared path definition file (`utils_paths.sh`)
- tool-specific module definition files (`utils_<tool>.sh`)

Each file:
- defines variables within its domain
- contains no logic
- introduces no side effects

| File | Responsibility |
|------|----------------|
| `utils_paths.sh` | Defines core directory variables derived from `ROOT_DIR` |
| `utils_bwa.sh` | Defines cluster module for `bwa` |
| `utils_samtools.sh` | Defines cluster module for `samtools` |

## `utils_paths.sh`
Defines all core directory paths derived from `ROOT_DIR`.

Typical variables include:

```text
ARRAY_DIR
FUNCTIONS_DIR
PIPELINE_DIR
PREFLIGHT_DIR
UTILS_DIR
```

Unlike many pipelines, `genome-index` does not define an `OUTPUT_DIR`.

### Design Note
- The pipeline operates directly on a reference FASTA file
- All outputs (index files) are written alongside the input reference
- No additional pipeline-owned writable directories are required

As a result:
- `DIR_ARRAY` is not used
- no directory creation logic is required in preflight

This reflects the atomic, reference-level nature of the pipeline.

## `utils_bwa.sh`
Defines the cluster-specific module required to provide the `bwa` executable.

Includes:
- `BWA_MODULE` — module name used with module load

Example:

```bash
apps/bwa-0.7.10.tcl
```

This variable is consumed by:
- `preflight_bwa.sh` (validation)
- `refindex.sh` (execution module)

## `utils_samtools.sh`
Defines the cluster-specific module required to provide the `samtools` executable.

Includes:
- `SAMTOOLS_MODULE` — module name used with module load

Example:
```bash
apps/samtools-1.9.tcl
```

This variable is consumed by:
- `preflight_samtools.sh` (validation)
- `refindex.sh` (execution module)

# Variable Ownership Model
Each variable is defined in the layer where its meaning originates:
- directory structure → `utils_paths.sh`
- tool module definitions → `utils_<tool>.sh`
- pipeline-derived variables → preflight layer

This ensures:
- no duplication
- no accidental redefinition
- no hidden dependencies

Each variable has a clear, single owner within the pipeline.

# Usage Pattern
Utility scripts are sourced by preflight scripts (and not by execution modules):

```bash
source "${UTILS_DIR}/utils_paths.sh"
source "${UTILS_DIR}/utils_bwa.sh"
source "${UTILS_DIR}/utils_samtools.sh"
```

# Key Rules
- Variables are validated during preflight
- Required variables are exported via the execution ABI
- Execution modules consume only exported variables
- Utility scripts are not sourced across SLURM boundaries
- Do not include logic (no loops, no conditionals)
- Do not perform validation
- Do not modify variables after definition
- Do not create or mutate runtime state
- Ensure variables are clearly named and unambiguous
- Keep all definitions deterministic and reproducible

# Summary
The `utils/` directory defines the static configuration layer of the `genome-index` pipeline.

It ensures that:
- all shared paths and tool module definitions are declared in one place
- variables are consistently defined and traceable
- preflight scripts can validate the environment deterministically
- execution layers operate on a stable, pre-validated configuration

This separation is fundamental to maintaining a:
- reproducible
- portable
- contract-driven HPC pipeline architecture

