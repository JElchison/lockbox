#!/bin/bash

# setup Bash environment
set -eufx -o pipefail

# setup variables
KEY_FILE_PATH=test.key
LOCKBOX_PATH=/tmp/lockbox
TOTAL_NUMBER_FILES=100
TEST_FILE_NUMBER=10
ROOT_FILE_NUMBER=42

# setup contents of lockbox
rm -rf "$LOCKBOX_PATH" || true
mkdir "$LOCKBOX_PATH"
for I in $(seq $TOTAL_NUMBER_FILES); do
    echo "Test $I" > "$LOCKBOX_PATH/$I"
done
sudo chown root:root "$LOCKBOX_PATH/$ROOT_FILE_NUMBER"

# print summary info about lockbox
ls -li "$LOCKBOX_PATH"
xxd -g4 "$LOCKBOX_PATH/$TEST_FILE_NUMBER"
xxd -g4 "$LOCKBOX_PATH/$ROOT_FILE_NUMBER"

# record inode and size info
ORIG_INODE=$(ls -i "$LOCKBOX_PATH/$TEST_FILE_NUMBER" | cut -d ' ' -f 1)
ORIG_SIZE=$(stat -c %s "$LOCKBOX_PATH/$TEST_FILE_NUMBER")

# generate key to be used for encryption
./gen_key.sh "$KEY_FILE_PATH"
# encrypt lockbox
./lockbox.sh "$LOCKBOX_PATH" "$(xxd -p "$KEY_FILE_PATH" | tr -d '\n')"

# print summary info about lockbox
ls -li "$LOCKBOX_PATH"
xxd -g4 "$LOCKBOX_PATH/$TEST_FILE_NUMBER"
xxd -g4 "$LOCKBOX_PATH/$ROOT_FILE_NUMBER"

# verify that inode and size are same
NEW_INODE=$(ls -i "$LOCKBOX_PATH/$TEST_FILE_NUMBER" | cut -d ' ' -f 1)
test "$NEW_INODE" -eq "$ORIG_INODE"
NEW_SIZE=$(stat -c %s "$LOCKBOX_PATH/$TEST_FILE_NUMBER")
test "$NEW_SIZE" -eq "$ORIG_SIZE"

# verify that file owned by root has not been modified
diff -q "$LOCKBOX_PATH/$ROOT_FILE_NUMBER" <(echo "Test $ROOT_FILE_NUMBER")

# verify that file contents have been changed
if diff -q "$LOCKBOX_PATH/$TEST_FILE_NUMBER" <(echo "Test $TEST_FILE_NUMBER"); then false; fi

# decrypt lockbox
./lockbox.sh -d "$LOCKBOX_PATH" "$(xxd -p "$KEY_FILE_PATH" | tr -d '\n')"

# print summary info about lockbox
ls -li "$LOCKBOX_PATH"
xxd -g4 "$LOCKBOX_PATH/$TEST_FILE_NUMBER"
xxd -g4 "$LOCKBOX_PATH/$ROOT_FILE_NUMBER"

# verify that inode and size are same
NEW_INODE=$(ls -i "$LOCKBOX_PATH/$TEST_FILE_NUMBER" | cut -d ' ' -f 1)
test "$NEW_INODE" -eq "$ORIG_INODE"
NEW_SIZE=$(stat -c %s "$LOCKBOX_PATH/$TEST_FILE_NUMBER")
test "$NEW_SIZE" -eq "$ORIG_SIZE"

# verify that all files are back to original contents
for I in $(seq $TOTAL_NUMBER_FILES); do
    diff -q "$LOCKBOX_PATH/$I" <(echo "Test $I")
done

# print success
echo "Test succeeded"
