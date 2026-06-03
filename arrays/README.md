# `arrays`

# Overview
The `arrays/` directory defines the declarative contract layer of the `genome-index` pipeline.

These files contain no executable logic and instead declare:
- required configuration variables
- required system binaries
- execution modules
- preflight validation order
- execution ABI (exported variable contract)

Together, they define the Application Binary Interface (ABI) of the pipeline and its complete structural specification.

# Design Principles
- Declarative only — no functions, no control flow
- Single source of truth for pipeline structure
- Explicit contracts that enforce reproducibility
- Consumed by preflight and execution layers
- No hidden dependencies — all required inputs are declared
- Minimality — only required state is declared

These principles ensure that:
- the pipeline remains deterministic
- validation is centralised
- execution is reproducible across HPC environments

# Files and Responsibilities
The directory contains five core contract definitions:

| File | Responsibility |
|------|----------------|
| `array_variables.sh` | Defines required user configuration variables |
| `array_binaries.sh` | Defines required system binaries |
| `array_pipeline.sh` | Defines execution modules |
| `array_preflight.sh` | Defines ordered preflight validation stages |

# Contract Types

## `array_variables.sh`
Defines all variables that must be provided in `config.sh`.

Example:
```bash
VARIABLE_ARRAY=(
    REF_FASTA
    BWA_CPUS
)
```

These variables:
- originate from user configuration
- are validated during preflight (`preflight_variables.sh`)
- must be non-empty before execution

Only variables required for this pipeline are included.

All tool and infrastructure variables are intentionally excluded.

## `array_binaries.sh`
Defines all required system-level commands used by the pipeline.

### Rules
- include only commands explicitly invoked in scripts
- include scheduler and orchestration tools
- include system binaries used in preflight and pipeline
- exclude tool-specific binaries (`bwa`, `samtools`)
- exclude shell built-ins and helper functions

### Final Definition

```text
BINARY_ARRAY=(
    sbatch
    tee
    mkdir
    chmod
    find
    grep
    module
)
```

### Scope
This contract defines the minimal runtime environment required for pipeline execution, independent of tool-specific environments.

## `array_pipeline.sh`
Defines all execution modules in the pipeline.

For this pipeline:
- a single module is defined
- execution order is handled in `pipeline.sh`, not here

Example:
```bash
PIPELINE_ARRAY=(
    "refindex.sh"
)
```

This ensures:
- all modules are explicitly declared
- all modules are validated during preflight
- no undeclared scripts are executed

## `array_preflight.sh`
Defines the ordered execution of preflight scripts.

Order is critical and must follow dependency flow:
```bash
PREFLIGHT_ARRAY=(
    "preflight_variables.sh"
    "preflight_input.sh"
    "preflight_binaries.sh"
    "preflight_exports.sh"
    "preflight_pipeline.sh"
    "preflight_bwa.sh"
    "preflight_samtools.sh"
)
```

This ordering enforces:
```text
correct producer → consumer relationships
validation of inputs before environment checks
separation between core validation and tool validation
```

Unlike more complex pipelines, tool-specific preflight scripts are included directly rather than appended dynamically.

## `array_exports.sh`
- Defines the execution ABI of the pipeline.
- This is the most critical contract in the pipeline.

### Final Definition
```bash
EXPORT_ARRAY=(
    REF_FASTA
    BWA_CPUS
    PIPELINE_DIR
    FUNCTIONS_DIR
    BWA_MODULE
    SAMTOOLS_MODULE
)
```

### Scope
This contract:
- defines all variables required across SLURM execution boundaries
- is converted into `SBATCH_EXPORTS` during preflight
- ensures no implicit environment state is relied upon

It guarantees:
- deterministic execution across compute nodes
- reproducibility across HPC environments
- strict separation between configuration and execution

### Design Note
Only variables that:
- cross a SLURM boundary
- are consumed by downstream scripts

are included.

The following are explicitly excluded:
- derived variables (`SBATCH_EXPORTS`)
- SLURM variables (`SLURM_*`)
- preflight-only variables (`ARRAY_DIR`, `UTILS_DIR`, `PREFLIGHT_DIR`)
- variables not required downstream

This enforces a minimal, explicit ABI.

# Execution Relationships

| Array | Consumed By | Purpose |
|------|-------------|--------|
| `VARIABLE_ARRAY` | `preflight_variables.sh` | Validate user configuration |
| `BINARY_ARRAY` | `preflight_binaries.sh` | Validate system environment |
| `PIPELINE_ARRAY` | `preflight_pipeline.sh` | Validate execution modules |
| `PREFLIGHT_ARRAY` | `preflight.sh` | Define validation order |
| `EXPORT_ARRAY` | `preflight_exports.sh`, `pipeline.sh` | Construct and propagate execution ABI |

# Key Rules
- Do not include logic or validation in arrays
- Do not dynamically modify arrays
- Ensure all entries correspond to real entities (variables, scripts, binaries)
- Maintain strict alignment with preflight and execution layers
- Keep contracts minimal — no unused entries
- Ensure export contract reflects actual downstream consumption
- Avoid circular definitions (e.g. derived variables such as `SBATCH_EXPORTS` must not be included)

# Summary
The `arrays/` directory defines the contractual backbone of the `genome-index` pipeline:
- what must be provided (variables)
- what must exist (binaries)
- what will be executed (modules)
- in what order validation occurs (preflight)
- what state crosses execution boundaries (execution ABI)

All pipeline behaviour is derived from these declarations, ensuring:
- deterministic execution
- reproducibility across environments
- strict contract-driven validation
- clear separation between validation and execution