#!/bin/bash

# check_bwa
# Verifies that bwa is available and supports the bwa mem subcommand.
#
# Arguments:
#   None
#
# Operation:
#   - Checks that the bwa command exists in PATH using check_command.
#   - Confirms that the bwa installation provides the "mem" subcommand
#     by inspecting bwa help output.
#   - Emits an error message if the required functionality is missing.
#
# Returns:
#   0 if bwa is available and supports bwa mem
#   1 if bwa is not found or does not support bwa mem
#
# Example:
#   check_bwa
check_bwa() {

    # Check general command
    check_command bwa || return 1

    # Check specific command
    bwa 2>&1 | grep -q "mem" \
        || {
            echo "  ERROR: bwa mem not available"
            return 1
        }

    return 0
}