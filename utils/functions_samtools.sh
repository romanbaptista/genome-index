#!/bin/bash

# check_samtools
# Verifies that samtools is available and supports the faidx command.
#
# Arguments:
#   None
#
# Operation:
#   - Checks that the samtools command exists in PATH using check_command.
#   - Confirms that the samtools installation provides the "faidx" command
#     by inspecting samtools help output.
#   - Emits an error message if the required functionality is missing.
#
# Returns:
#   0 if samtools is available and supports samtools faidx
#   1 if samtools is not found or does not support samtools faidx
#
# Example:
#   check_samtools
check_samtools() {

    # Check general command
    check_command samtools || return 1

    # Check specific command
    samtools 2>&1 | grep -q "faidx" \
        || {
            echo "  ERROR: samtools faidx not available"
            return 1
        }

    return 0
}