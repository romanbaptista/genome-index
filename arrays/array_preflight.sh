#!/bin/bash

######################### MAIN ###########################

# PREFLIGHT_ARRAY:
# Ordered list of preflight validation scripts.
#
# Scope:
#   - Used by preflight.sh to control execution order of validation steps.
#   - Defines the full validation layer of the pipeline.
#
# Notes:
#   - Order is critical and must respect dependency flow:
#       variables → binaries → inputs → exports → pipeline → tools
#   - Scripts are sourced sequentially and must be fail-fast.
#   - Tool-specific preflight scripts are appended after core validation.
#   - No execution logic is permitted in preflight scripts.

# Define preflight array (validation order)
PREFLIGHT_ARRAY=(
    "preflight_variables.sh"
    "preflight_input.sh"
    "preflight_binaries.sh"
    "preflight_exports.sh"
    "preflight_pipeline.sh"
    "preflight_bwa.sh"
    "preflight_samtools.sh"
)