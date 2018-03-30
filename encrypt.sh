#!/bin/bash

# setup Bash environment
set -eufx -o pipefail


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
Bash script to format a block device (hard drive or Flash drive) in UDF.
The output is a drive that can be used for reading/writing across multiple
operating system families: Windows, macOS, and Linux.
This script should be capable of running in macOS or in Linux.
Usage:  $0 [-b BLOCK_SIZE] [-f] [-p PARTITION_TYPE] [-w WIPE_METHOD] device label
        $0 -v
        $0 -h
    -b BLOCK_SIZE
        Block size to be used during format operation.
        If absent, defaults to value reported by blockdev/diskutil.
        This is an expert-only option.  Please consult the README for details.
    -f
        Forces non-interactive mode.  Useful for scripting.
        Please use with caution, as no user confirmation is given.
    -h
        Display help information and exit.
    -p PARTITION_TYPE
        Partition type to set during format operation.
        Currently supported types include:  mbr, none
            mbr  - Master boot record (default)
            none - Do not modify partitions
        If absent, defaults to 'mbr'.
        See also:
            https://github.com/JElchison/format-udf#why
    -v
        Display version information and exit.
    -w WIPE_METHOD
        Wipe method to be used before format operation.
        Currently supported types include:  quick, zero, scrub
            quick - Quick method (default)
            zero  - Write zeros to the entire device
            scrub - Iteratively writes patterns on device
                    to make retrieving the data more difficult.
                    Requires 'scrub' to be executable and in the PATH.
                    See also http://linux.die.net/man/1/scrub
        If absent, defaults to 'quick'.
        Note:  'zero' and 'scrub' methods will take a long time.
    device
        Device to format.  Should be of the form:
          * sdx   (Linux, where 'x' is a letter) or
          * diskN (macOS, where 'N' is a number)
    label
        Label to apply to formatted device.
Example:  $0 sdg "My UDF External Drive"
EOF
}


# Prints hex representation of CHS (cylinder-head-sector) to stdout
# Arguments:
#   Logical block address (LBA)
# Returns:
#   None
function encrypt {
    FILE=$1

    echo "Hello, $FILE"
    echo "Key = $KEY_HEX"
}
export -f encrypt


###############################################################################
# validate arguments
###############################################################################

echo "[+] Validating arguments..."

# require exactly 2 arguments
if [[ $# -ne 2 ]]; then
    print_usage
    exit 1
fi

# setup variables for arguments
ROOT_DIR=$1
KEY_HEX=$2
export KEY_HEX


###############################################################################
# start encryption
###############################################################################

find "$ROOT_DIR" -type f -exec bash -c 'encrypt "$0"' {} \;


###############################################################################
# success
###############################################################################

echo "[+] Success"
