# `functions`

# Overview
The `functions/` directory contains all reusable, atomic logic used throughout the `genome-index` pipeline.

These scripts provide:
- validation primitives
- filesystem checks and operations
- command and runtime checks
- shared utility operations

They represent the execution logic layer, but are strictly limited to stateless, reusable operations.

Unlike more complex pipelines, `genome-index` uses a minimal functions layer, containing only a shared base implementation.

# Design Principles

| Principle | Description |
|----------|------------|
| Atomicity | Each function performs a single, well-defined task |
| No orchestration | Control flow handled externally in scripts |
| Validation-first | Inputs validated before execution |
| Return-based | Failures propagate via return codes |

These principles ensure that:
- logic is modular and reusable
- failure handling is consistent and predictable
- orchestration remains external to function definitions

# File Overview
The `functions/` directory is intentionally minimal:
- a single shared base layer (`functions_base.sh`)
- no tool-specific helper layers

| File | Responsibility |
|------|----------------|
| `functions_base.sh` | Core validation, filesystem operations, and error handling |

## `functions_base.sh`
This file defines all core helper functions used across the entire pipeline.

It forms the foundation of the pipeline’s contract-driven validation system.

### Responsibilities
Includes:
- argument validation (`arg_check_nonempty`)
- variable validation (`variable_check_nonempty`)
- array validation (`array_check_nonempty`)
- directory checks:
    - existence
    - non-emptiness
    - filetype filtering
- file checks:
    - existence
    - non-emptiness
    - executability
- filesystem operations:
    - `directory_create`
    - permission handling
- command validation:
    - `tool_check_binary`
    - `tool_check_runtime`
    - `tool_check_subcommand`
- structured error handling:
    - `fail_message`

# Design Characteristics
- all functions are atomic
- all functions validate inputs before execution
- no orchestration or control flow is implemented
- no side effects beyond function return values
- failures propagate via return codes, not exit

# Role in the Pipeline
This file is:
- sourced by the entrypoint (`genome-index.sh`)
- used implicitly across preflight (same-shell model)
- explicitly sourced in SLURM-executed scripts:
    - `pipeline.sh`
    - `refindex.sh`

It provides the only logic dependency shared across all layers.

# Execution Pattern
Functions follow a strict internal structure:

```bash
my_function() {
    local arg="${1-}"

    # VALIDATION
    arg_check_nonempty "${arg}" || return $?

    # FUNCTION
    perform_operation "${arg}" || return 1
}
```

This pattern guarantees:
- predictable behaviour
- clear error propagation
- composability across scripts

# Usage in Pipeline
Functions are used across:
```text
preflight scripts → validation and environment assurance
pipeline scripts → limited orchestration helpers (e.g. guards, logging)
execution modules → filesystem operations and error handling
```

Scripts explicitly source required functions when crossing execution boundaries:

```bash
source "${FUNCTIONS_DIR}/functions_base.sh"
```

No implicit availability is assumed across SLURM boundaries.

# Execution Boundary Model
The pipeline enforces strict behaviour across execution contexts:

- same shell (entrypoint → preflight) → functions are inherited
- SLURM job (`pipeline.sh`) → functions are explicitly re-sourced
- SLURM job (`refindex.sh`) → functions are explicitly re-sourced
- no function state is inherited across boundaries

This ensures:
- deterministic behaviour
- no hidden dependencies
- reproducibility across execution environments

# Error Handling
Functions:
- return non-zero exit codes on failure
- do not terminate execution directly

Scripts handle failure using:

```bash
function_call || fail_message "error description"
```

This ensures:
- centralised failure handling
- consistent error messaging
- separation between logic and control flow

# Variable and Validation Model
Functions implement a layered validation system:
- `arg_check_nonempty` → validates function arguments
- `variable_check_nonempty` → validates named pipeline variables
- `array_check_nonempty` → validates arrays

Each function:
- validates only its own inputs
- does not assume upstream guarantees unless explicitly enforced

This allows validation to remain:
- composable
- explicit
- layered across the pipeline

# Minimal Design Note
Unlike many pipelines, genome-index does not include tool-specific function layers (e.g. `functions_bwa.sh`).

This is because:
- no installation logic is required
- tool validation is simple and handled directly in preflight
- the HPC module system provides all required tool environments

This results in a leaner, simpler functions layer without sacrificing correctness or reproducibility.

# Key Rules
- Do not include orchestration logic in functions
- Do not use exit inside functions
- Always validate inputs before execution
- Keep functions minimal and focused
- Avoid hidden dependencies or global state
- Ensure functions are reusable across pipeline contexts

# Summary
The `functions/` directory provides the core logic building blocks of the `genome-index` pipeline.

It enables:
- consistent validation and error handling
- strict separation between logic and orchestration
- modular, reusable components

All higher-level behaviour in the pipeline is constructed from these atomic functions, ensuring:
- clarity of responsibility
- reproducibility
- maintainability