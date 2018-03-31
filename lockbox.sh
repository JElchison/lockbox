#!/bin/bash

# setup Bash environment
set -euf -o pipefail


###############################################################################
# constants
###############################################################################

# version of this script
VERSION=1.0.0


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
Maintain a private lockbox of data, accessible only by you.
Performs fast file-by-file encryption on every file in a directory recursively.
This script should be capable of running in macOS or in Linux.
Usage:  $0 [-e] [-d] path key
        $0 -v
        $0 -h
    -e
        Encrypt mode (default).
    -d
        Decrypt mode.
    -h
        Display help information and exit.
    -v
        Display version information and exit.
    path
        Path to lockbox directory.
    key
        Key to be used for encryption/decryption.
        Must be represented as a string comprised of exactly 64 hex characters,
        corresponding to a 256-bit (or 32-byte) key.
Example:  $0 /tmp/lockbox aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
Example:  $0 /tmp/lockbox \$(xxd -p test.key | tr -d '\n')
EOF
}


# Calculates IV for given file path
# Arguments:
#   Absolute file path
# Returns:
#   128-bit IV, represented in hex
function get_iv_hex {
    set -euf -o pipefail

    FILE_PATH=$1

    # MD5 is safe here because it's not being used for cryptographic reasons.
    # we just need something 128 bits wide that is likely to be different for
    # each input file path.
    FILE_PATH_HASH_HEX=$(echo -n "$FILE_PATH" | md5sum | cut -d ' ' -f 1)

    openssl enc -aes-256-ecb -in <(echo "$FILE_PATH_HASH_HEX" | xxd -r -p) -e -K "$KEY_HASH_HEX" -nopad | xxd -p | tr -d '\n'
}
export -f get_iv_hex


# Encrypts or decrypts a file
# Arguments:
#   Absolute file path
# Returns:
#   None
function crypt {
    set -euf -o pipefail

    FILE_PATH=$1

    openssl enc -aes-256-ctr -in "$FILE_PATH" "$OPERATION_SWITCH" -K "$KEY_HEX" -iv "$(get_iv_hex "$FILE_PATH")" | dd of="$FILE_PATH" conv=notrunc status=none
}
export -f crypt


###############################################################################
# set default options
###############################################################################

OPERATION="Encrypt"
OPERATION_SWITCH='-e'

# reset in case getopts has been used previously in the shell
OPTIND=1


###############################################################################
# parse options
###############################################################################

while getopts ":edvh" opt; do
    case $opt in
        e)
            OPERATION="Encrypt"
            OPERATION_SWITCH='-e'
            ;;
        d)
            OPERATION="Decrypt"
            OPERATION_SWITCH='-d'
            ;;
        v)
            echo "lockbox $VERSION"
            echo "https://github.com/JElchison/lockbox"
            echo "Copyright (C) 2018 Jonathan Elchison <JElchison@gmail.com>"
            exit 0
            ;;
        h)
            print_usage
            exit 0
            ;;
        \?)
            echo "[-] Invalid option '-$OPTARG'" >&2
            print_usage
            exit 1
            ;;
        :)
            echo "[-] Option '-$OPTARG' requires an argument" >&2
            print_usage
            exit 1
            ;;
    esac
done

shift $((OPTIND-1))
([[ "$1" = "--" ]] 2>/dev/null && shift) || true

# export variables for use by child processes
export OPERATION_SWITCH


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

# verify that ROOT_DIR is a valid directory
[[ -d "$ROOT_DIR" ]] || (echo "[-] $ROOT_DIR either doesn't exist or is not a directory" >&2; false)

# verify that key is valid
echo -n "$KEY_HEX" | grep -Eq '[a-fA-F0-9]{64}' || (echo "[-] Provided key is invalid or incorrectly formatted" >&2; false)
echo -n "$KEY_HEX" | grep -Eq '[a]{64}' && (echo "[-] Provided key is only valid as example.  Please use gen_key.sh." >&2; false)

# export variables for use by child processes
export KEY_HEX


###############################################################################
# test dependencies
###############################################################################

echo "[+] Testing dependencies..."
if [[ ! -x $(which openssl 2>/dev/null) ]] ||
    [[ ! -x $(which md5sum 2>/dev/null) ]] ||
    [[ ! -x $(which sha256sum 2>/dev/null) ]] ||
    [[ ! -x $(which cat 2>/dev/null) ]] ||
    [[ ! -x $(which cut 2>/dev/null) ]] ||
    [[ ! -x $(which find 2>/dev/null) ]] ||
    [[ ! -x $(which grep 2>/dev/null) ]] ||
    [[ ! -x $(which test 2>/dev/null) ]] ||
    [[ ! -x $(which true 2>/dev/null) ]] ||
    [[ ! -x $(which false 2>/dev/null) ]] ||
    [[ ! -x $(which tr 2>/dev/null) ]] ||
    [[ ! -x $(which dd 2>/dev/null) ]] ||
    [[ ! -x $(which xxd 2>/dev/null) ]]; then
    echo "[-] Dependencies unmet.  Please verify that the following are installed, executable, and in the PATH:  openssl, md5sum, sha256sum, cat, cut, find, grep, test, true, false, tr, dd, xxd" >&2
    exit 1
fi


###############################################################################
# start operation
###############################################################################

KEY_HASH_HEX=$(echo "$KEY_HEX" | xxd -r -p | sha256sum | cut -d ' ' -f 1)
export KEY_HASH_HEX

echo "[*] ${OPERATION}ing following files..."
find "$ROOT_DIR" -type f -writable -print -exec bash -c 'crypt "$0"' {} \;


###############################################################################
# report status
###############################################################################

echo "[+] Success"