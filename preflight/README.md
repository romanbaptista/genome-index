# `preflight`

# Overview
The `preflight/` directory implements the validation and environment construction layer of the `genome-index` pipeline.

This layer is responsible for ensuring that all requirements are satisfied before any SLURM jobs are submitted.

It performs:
- validation of user configuration
- validation of system environment
- validation of reference FASTA input
- validation of pipeline structure
- validation of tool availability (`bwa`, `samtools`)
- construction of the execution ABI (`SBATCH_EXPORTS`)

The preflight phase enforces a strict fail‑fast model, guaranteeing that downstream execution begins only in a fully validated and deterministic state.

# Design Principles
The preflight layer follows core architectural rules:
- Fail-fast — any error immediately terminates the pipeline
- Validation-only responsibility — no data processing or module execution
- Deterministic ordering — all steps run in a strictly defined sequence
- Explicit contracts — validation driven entirely by declarative arrays
- No hidden state — all required variables, tools, and inputs are explicitly checked
- Reproducibility — tool environments are validated deterministically via HPC modules

This ensures that all downstream scripts can assume:
- consistent state
- valid inputs
- functional tools
- fully constructed execution environment

# Role in the Pipeline
The preflight layer is executed immediately after the entrypoint script (`genome-index.sh`) and before any SLURM submission occurs.

It ensures:
- all required configuration variables are defined and non-empty
- all required system binaries are available
- the reference FASTA file is valid and usable
- all pipeline scripts exist and are executable
- required HPC modules can be loaded successfully
- required tool functionality is available (`bwa mem`, `samtools faidx`)
- the execution ABI is fully constructed and ready for export

Only once all checks succeed does execution proceed to the pipeline orchestration stage.

# Execution Flow
Preflight is orchestrated by `preflight.sh`.

This script:
- sources `array_preflight.sh`
- validates the `PREFLIGHT_ARRAY` contract
- executes each preflight script in strict order
- terminates immediately on failure

Each script:
- consumes only validated upstream state
- performs validation within its domain
- guarantees correctness of its layer

This enforces a strict producer → consumer relationship across validation stages.

# Preflight Stages
The pipeline implements the following validation stages:

### Variables
- Validates core user-defined variables from `config.sh`
- Ensures all required configuration inputs are defined and non-empty

### Input
- Validates reference FASTA file existence
- Confirms file contains data
- Validates accepted file extensions (`.fa`, `.fasta`, `.fna`)
- This ensures a valid and usable reference genome is provided.

### Binaries
- Verifies required system-level CLI tools from `BINARY_ARRAY`
- Ensures core runtime environment is available
- Tool-specific binaries are validated separately.

### Exports
- Constructs the execution ABI from `EXPORT_ARRAY`
- Exports all required pipeline variables
- Generates `SBATCH_EXPORTS` for SLURM environment propagation

### Pipeline
- Confirms all execution modules defined in `PIPELINE_ARRAY` exist
- Ensures scripts are non-empty and executable
- Validates presence of `pipeline.sh` orchestrator

### Tool Validation
- Loads HPC modules for `bwa` and `samtools`
- Verifies binaries are available in PATH
- Confirms required functionality:
    - `bwa mem`
    - `samtools faidx`

Unlike other pipelines, no tool installation is performed — tools are assumed to be provided via the cluster module system.

# Script Structure
Each preflight script follows a consistent structure:

```text
GUARDS
SETUP
SOURCE
CHECKS
MAIN
```

- `GUARDS` validate required variables
- `SETUP` defines script-level constants
- `SOURCE` imports required arrays or utilities
- `CHECKS` validates consumed state
- `MAIN` performs validation

This ensures:
- predictable control flow
- explicit dependencies
- strict separation between validation stages

# Tool Integration Model
Tools in genome-index are integrated using a simplified model:
- `utils_<tool>.sh` → defines module name
- `preflight_<tool>.sh` → validates module and functionality

No `functions_<tool>.sh` layer is required in this pipeline because:
- no installation logic is needed
- validation is minimal and direct

This reflects a module-based tool provisioning model rather than an installation-based one.

# Execution ABI
The preflight layer constructs the execution ABI using:
```text
array_exports.sh → defines required variables
preflight_exports.sh → validates and exports variables
```

This produces:
```text
SBATCH_EXPORTS
```

which is then passed across the SLURM boundary via:
```bash
sbatch --export="${SBATCH_EXPORTS}"
```

This ensures:
- only required variables are propagated
- no implicit state is relied upon
- execution environments are deterministic and reproducible

# Execution Relationships

| Script | Responsibility |
|--------|----------------|
| `preflight.sh` | Orchestrates execution of all preflight stages |
| `preflight_variables.sh` | Validates user configuration variables |
| `preflight_input.sh` | Validates reference FASTA |
| `preflight_binaries.sh` | Validates required system binaries |
| `preflight_exports.sh` | Constructs SBATCH_EXPORTS from `EXPORT_ARRAY` |
| `preflight_pipeline.sh` | Validates pipeline scripts and orchestrator |
| `preflight_bwa.sh` | Validates bwa module and functionality |
| `preflight_samtools.sh` | Validates samtools module and functionality |

# Key Rules
- Do not include execution logic in preflight scripts
- Do not defer validation to downstream stages
- Always fail immediately on error
- Only validate variables consumed by the script
- Maintain strict ordering via `PREFLIGHT_ARRAY`
- Do not rely on implicit environment state across boundaries
- Ensure all execution dependencies are satisfied before completion
- Treat SLURM execution as a strict boundary

# Summary
The `preflight/` directory guarantees that the pipeline executes in an environment that is:
- fully validated
- reproducible
- deterministic

By enforcing strict contracts and fail-fast validation, it provides a clean boundary between setup and execution.

This ensures that all downstream pipeline stages operate:
- without ambiguity
- without hidden dependencies
- with full confidence in their execution context