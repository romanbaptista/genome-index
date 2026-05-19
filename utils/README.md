# `utils`
This directory contains shared utility functions used by the `genome-index` pipeline.

The scripts in `utils/` provide reusable, strictly validated helper functions that support:
- Preflight validation
- HPC module loading validation and enforcement
- Defensive error handling
- Deterministic pipeline behavior under strict Bash execution
- Canonical definition of pipeline structure and execution ABI

Utility scripts are sourced by `run_pipeline.sh`, preflight scripts, and tool‑specific validation layers where required.

# Design Contract
All utility scripts adhere to the following principles:
- Pure helper logic only (no pipeline orchestration)
- Safe operation under `set -euo pipefail`
- Explicit, readable control flow
- Clear and actionable error messages
- No reliance on implicit environment state
- No modification of global system settings
- Portable across HPC environments
- Canonical definition of pipeline structure via arrays

Utility functions are stateless and rely entirely on arguments and inherited environment variables.

# Utility Script Overview

```text
arrays.sh
functions_base.sh
functions_bwa.sh
functions_samtools.sh
```

Each utility script serves a narrow, well-defined purpose and is designed to be reused across multiple pipeline stages.

## `arrays.sh`
Defines the canonical structure and execution contract of the pipeline.

### Responsibilities
Defines ordered lists of:
- Preflight scripts (`PREFLIGHT_ARRAY`)
- Execution modules (`SCRIPT_ARRAY`)
- Execution ABI (`EXPORT_ARRAY`)
- Required commands (`COMMAND_ARRAY`)
- Required configuration variables (`VARIABLE_ARRAY`)

Also defines cluster-specific module identifiers:
- `BWA_MODULE`
- `SAMTOOLS_MODULE`

### Guarantees
- Provides a single source of truth for pipeline structure
- Ensures consistent validation and execution ordering
- Defines the complete set of pipeline-owned variables propagated across SLURM boundaries
- Defines the complete set of external dependencies required for execution
- Encodes cluster-specific tool configuration in a controlled and explicit way

### Design Notes
- `EXPORT_ARRAY` defines the execution ABI and must not be modified downstream
- Only pipeline-owned variables appear in `EXPORT_ARRAY` (never SLURM variables)
- `SBATCH_EXPORTS` is a derived snapshot and is not part of the canonical ABI
- Module definitions (`BWA_MODULE`, `SAMTOOLS_MODULE`) are intentionally excluded from `EXPORT_ARRAY`
- `COMMAND_ARRAY` defines the full validation surface for external commands


## `functions_base.sh`
Provides core validation and helper functions used throughout the pipeline.

### Responsibilities
- Validates files, directories, variables, and commands
- Enforces non-empty configuration values
- Provides consistent error handling and messaging
- Guards against common Bash failure modes
- Supports deterministic and fail-safe validation behavior

### Functions
| Function | Purpose |
|----------|--------|
| `check_file` | Confirms that a regular file exists |
| `check_file_data` | Confirms that a file exists and is non-empty |
| `check_directory` | Confirms that a directory exists |
| `check_variable` | Confirms that a variable is set and non-empty |
| `check_string` | Confirms that a string is non-empty |
| `check_command` | Confirms that a command is available in PATH |
| `check_executable` | Confirms that a file exists and is executable |
| `make_executable` | Adds executable permissions to a file |
| `check_arg` | Confirms that required function arguments are provided |
| `fail` | Prints an error message and exits immediately |
| `write_env` | Writes a reproducible environment file |
| `get_directory` | Resolves the directory of a path |
| `get_parent_directory` | Resolves the parent directory of a path |

These functions are used extensively by preflight scripts to enforce pipeline invariants before any SLURM job submission.

## `functions_bwa.sh`
Provides `bwa`‑specific validation helpers.

### Responsibilities
- Confirms that the `bwa` command is available
- Verifies that `bwa` supports the `mem` subcommand
- Provides a clean abstraction for tool validation within preflight

### Functions
| Function | Purpose |
|----------|--------|
| `check_bwa` | Verifies availability of `bwa` and confirms support for `bwa mem` |

### Design Notes
- Does not install `bwa`
- Assumes module-based provisioning via `preflight_bwa.sh`
- Intended for use exclusively in the preflight validation layer

## `functions_samtools.sh`
Provides `samtools`‑specific validation helpers.

### Responsibilities
- Confirms that the `samtools` command is available
- Verifies that `samtools` supports the `faidx` command
- Provides a clean abstraction for tool validation within preflight

#### Functions
| Function | Purpose |
|----------|--------|
| `check_samtools` | Verifies availability of `samtools` and confirms support for `samtools faidx` |

### Design Notes
- Does not install `samtools`
- Assumes module-based provisioning via `preflight_samtools.sh`
- Intended for use exclusively in the preflight validation layer

# Usage
Utility scripts are not intended to be executed directly; they are sourced where required.

`arrays.sh` is sourced by:
- `run_pipeline.sh`
- preflight scripts

`functions_base.sh` is sourced by:
- `run_pipeline.sh`
- all preflight scripts

`functions_bwa.sh` and `functions_samtools.sh` are sourced only within tool-specific preflight scripts

Execution modules do not depend on utility functions and consume only:
- the execution ABI (`EXPORT_ARRAY`)
- SLURM-provided variables

# Error Handling
All utility functions are designed to:
- Fail immediately on invalid input
- Emit concise, context-aware error messages
- Prevent execution from progressing in an unsafe state

This ensures that failures occur during the validation stage rather than during compute jobs.

# Notes
- Utility functions duplicate no validation logic found elsewhere
- All validation is centralised in the preflight layer
- Module scripts do not perform validation
- Arrays define the canonical pipeline structure and must remain immutable
- Tool provisioning is handled via HPC modules, not local installation
- Module loading is explicit, reproducible, and cluster-dependent
- Functions make no assumptions about SLURM execution context

Adding new tools requires:
- tool-specific utility helpers
- corresponding preflight integration
- updates to `COMMAND_ARRAY` and module definitions