#!/bin/bash

# setup Bash environment
set -euf -o pipefail


###############################################################################
# functions
###############################################################################

# Prints script usage to stderr
# Arguments:
#   None
# Returns:
#   None
print_usage() {
    cat <<EOF >&2
Generates a 256-bit key for use by lockbox.sh.
Usage:  $0 key_path
    key_path
        Path to output key file.
Example:  $0 test.key
EOF
}


###############################################################################
# validate arguments
###############################################################################

echo "[+] Validating arguments..."

# require exactly 1 argument
if [[ $# -ne 1 ]]; then
    print_usage
    exit 1
fi

# setup variables for arguments
OUTPUT_FILE=$1


###############################################################################
# generate key
###############################################################################

head -c 32 /dev/random > "$OUTPUT_FILE"
echo "[+] Key saved at $OUTPUT_FILE"


###############################################################################
# report status
###############################################################################

echo "[+] Success"
