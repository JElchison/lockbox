#!/bin/bash

# setup Bash environment
set -eufx -o pipefail


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

head -c 16 /dev/random > "$OUTPUT_FILE"
echo "[+] Key saved at $OUTPUT_FILE"


###############################################################################
# success
###############################################################################

echo "[+] Success"
