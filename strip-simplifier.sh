#!/bin/bash
# Usage:
#   To strip: ./strip-simplifier.sh -e executable [-f functions_file] [-g globals_file]
#   To restore: ./strip-simplifier.sh -e executable -r
#
# Options:
#   -e executable     : Name of the executable to process (mandatory).
#   -f functions_file : File containing the names of functions to strip (optional).
#   -g globals_file   : File containing the names of global variables to strip (optional).
#   -r                : Restore the backup (.backup) to the executable.
#   -h                : Show this help message.

# Function to execute a command and check its result
run_command() {
    "$@"
    if [ $? -ne 0 ]; then
        echo "Error while executing the command: $*"
        exit 1
    fi
}

usage() {
  echo "Usage: $0 -e executable [-f functions_file] [-g globals_file] [-r]"
  echo "   -e executable     : Name of the executable to process (mandatory)."
  echo "   -f functions_file : File containing the names of functions to strip (optional)."
  echo "   -g globals_file   : File containing the names of global variables to strip (optional)."
  echo "   -r                : Restore the backup (.backup) to the executable."
  echo "   -h                : Show this help message."
  exit 1
}

# Parsing arguments
RESTORE=0
while getopts ":e:f:g:rh" opt; do
    case $opt in
        e)
            EXECUTABLE="$OPTARG"
            ;;
        f)
            FUNCTIONS_FILE="$OPTARG"
            ;;
        g)
            GLOBALS_FILE="$OPTARG"
            ;;
        r)
            RESTORE=1
            ;;
        h)
            usage
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            usage
            ;;
        :)
            echo "Option -$OPTARG requires an argument." >&2
            usage
            ;;
    esac
done

# Check executable existence
if [ -z "$EXECUTABLE" ]; then
    echo "Error: the executable is mandatory."
    usage
fi

if [ ! -f "$EXECUTABLE" ]; then
    echo "Error: the executable '$EXECUTABLE' does not exist."
    exit 1
fi

# If restore flag is set, perform restoration and exit
if [ $RESTORE -eq 1 ]; then
    BACKUP_FILE="${EXECUTABLE}.backup"
    if [ ! -f "$BACKUP_FILE" ]; then
        echo "Error: Backup file '$BACKUP_FILE' does not exist. Cannot restore."
        exit 1
    fi
    echo "Restoring backup from '$BACKUP_FILE' to '$EXECUTABLE'..."
    run_command cp "$BACKUP_FILE" "$EXECUTABLE"
    echo "Restoration completed successfully."
    exit 0
fi

# Create a backup of the executable
run_command cp "$EXECUTABLE" "${EXECUTABLE}.backup"

echo "=== Initial state of symbols ==="
if [ -n "$GLOBALS_FILE" ]; then
    echo "Global variables present:"
    run_command nm "$EXECUTABLE" | grep -f "$GLOBALS_FILE"
fi

if [ -n "$FUNCTIONS_FILE" ]; then
    echo -e "\nFunctions present:"
    run_command nm "$EXECUTABLE" | grep -f "$FUNCTIONS_FILE"
fi

# If no files for functions and globals are provided, perform a full strip
if [ -z "$GLOBALS_FILE" ] && [ -z "$FUNCTIONS_FILE" ]; then
    echo -e "\nNo function or global variable file provided, performing a full strip."
    run_command strip "$EXECUTABLE"
    echo "Full strip completed. Backup saved as ${EXECUTABLE}.backup"
    exit 0
fi

# Perform strip for global variables if the file is provided
if [ -n "$GLOBALS_FILE" ]; then
    echo -e "\n=== Removing global variables ==="
    while read -r symbol; do
        # Skip empty lines
        if [ -n "$symbol" ]; then
            echo "Removing global symbol: $symbol"
            run_command strip --strip-symbol="$symbol" "$EXECUTABLE"
            run_command objcopy --strip-symbol="$symbol" "$EXECUTABLE" "$EXECUTABLE.tmp"
            run_command mv "$EXECUTABLE.tmp" "$EXECUTABLE"
        fi
    done < "$GLOBALS_FILE"
fi

# Perform strip for functions if the file is provided
if [ -n "$FUNCTIONS_FILE" ]; then
    echo -e "\n=== Removing functions ==="
    while read -r symbol; do
        if [ -n "$symbol" ]; then
            echo "Removing function: $symbol"
            run_command strip --strip-symbol="$symbol" "$EXECUTABLE"
            run_command objcopy --strip-symbol="$symbol" "$EXECUTABLE" "$EXECUTABLE.tmp"
            run_command mv "$EXECUTABLE.tmp" "$EXECUTABLE"
        fi
    done < "$FUNCTIONS_FILE"
fi

echo -e "\n=== Final verification ==="
if [ -n "$GLOBALS_FILE" ]; then
    echo "Verifying remaining global variables:"
    nm "$EXECUTABLE" | grep -f "$GLOBALS_FILE"
fi

if [ -n "$FUNCTIONS_FILE" ]; then
    echo -e "\nVerifying remaining functions:"
    nm "$EXECUTABLE" | grep -f "$FUNCTIONS_FILE"
fi

echo -e "\nProcess completed. Backup saved as ${EXECUTABLE}.backup"
