#!/bin/bash
# Usage:
#   To strip: ./strip-simplifier.sh -e executable [-f functions_file] [-g globals_file] [-y]
#   To restore: ./strip-simplifier.sh -e executable -r [-y]
#
# Options:
#   -e executable         : Name of the executable to process (mandatory).
#   -f functions_file     : File containing the names of functions to strip (optional).
#   -g globals_file       : File containing the names of global variables to strip (optional).
#   -r                    : Restore the backup (.backup) to the executable.
#   -y                    : If no symbol files are provided, ask interactively for symbols to strip. Otherwise, do full strip.
#   -h                    : Show this help message.

# Function to execute a command and check its result
run_command() {
    "$@"
    if [ $? -ne 0 ]; then
        echo "Error while executing the command: $*"
        exit 1
    fi
}

usage() {
  echo "Usage: $0 -e executable [-f functions_file] [-g globals_file] [-r] [-y]"
  echo "   -e executable         : Name of the executable to process (mandatory)."
  echo "   -f functions_file     : File containing the names of functions to strip (optional)."
  echo "   -g globals_file       : File containing the names of global variables to strip (optional)."
  echo "   -r                    : Restore the backup (.backup) to the executable."
  echo "   -y                    : If no symbol files are provided, ask interactively for symbols to strip. Otherwise, do full strip."
  echo "   -h                    : Show this help message."
  exit 1
}

# Default values
RESTORE=0
INTERACTIVE_STRIP=0  # If set to 1, enter prompt mode to ask for symbols if no files are provided

# Parsing arguments
while getopts ":e:f:g:ryh" opt; do
    case $opt in
        e) EXECUTABLE="$OPTARG" ;;
        f) FUNCTIONS_FILE="$OPTARG" ;;
        g) GLOBALS_FILE="$OPTARG" ;;
        r) RESTORE=1 ;;
        y) INTERACTIVE_STRIP=1 ;;
        h) usage ;;
        \?) echo "Invalid option: -$OPTARG" >&2; usage ;;
        :) echo "Option -$OPTARG requires an argument." >&2; usage ;;
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

# If no symbol files are provided
if [ -z "$GLOBALS_FILE" ] && [ -z "$FUNCTIONS_FILE" ]; then
    if [ $INTERACTIVE_STRIP -eq 1 ]; then
        echo "No symbol files provided. Enter interactive mode to specify symbols."

        echo "Enter function names to strip (one per line). Press Enter on an empty line to finish:"
        FUNCTIONS_FILE=$(mktemp)
        while IFS= read -r line; do
            [ -z "$line" ] && break
            echo "$line" >> "$FUNCTIONS_FILE"
        done

        echo "Enter global variable names to strip (one per line). Press Enter on an empty line to finish:"
        GLOBALS_FILE=$(mktemp)
        while IFS= read -r line; do
            [ -z "$line" ] && break
            echo "$line" >> "$GLOBALS_FILE"
        done
    else
        echo "No symbol files provided. Performing full strip."
        run_command strip "$EXECUTABLE"
        echo "Full strip completed. Backup saved as ${EXECUTABLE}.backup"
        exit 0
    fi
fi

echo "=== Initial state of symbols ==="
if [ -n "$GLOBALS_FILE" ]; then
    echo "Global variables present:"
    run_command nm "$EXECUTABLE" | grep -f "$GLOBALS_FILE"
fi

if [ -n "$FUNCTIONS_FILE" ]; then
    echo -e "\nFunctions present:"
    run_command nm "$EXECUTABLE" | grep -f "$FUNCTIONS_FILE"
fi

# Perform strip for global variables if the file is provided
if [ -n "$GLOBALS_FILE" ]; then
    echo -e "\n=== Removing global variables ==="
    while read -r symbol; do
        # Skip empty lines
        if [ -n "$symbol" ]; then
            echo "Removing global symbol: $symbol"
            run_command strip --strip-symbol="$symbol" "$EXECUTABLE"
            run_command objcopy --strip-symbol="$symbol" "$EXECUTABLE" "${EXECUTABLE}.tmp"
            run_command mv "${EXECUTABLE}.tmp" "$EXECUTABLE"
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
            run_command objcopy --strip-symbol="$symbol" "$EXECUTABLE" "${EXECUTABLE}.tmp"
            run_command mv "${EXECUTABLE}.tmp" "$EXECUTABLE"
        fi
    done < "$FUNCTIONS_FILE"
fi

echo -e "\n=== Final verification ==="
if [ -n "$GLOBALS_FILE" ]; then
    echo "Verifying if there are any remaining global variables from the one to be removed:"
    nm "$EXECUTABLE" | grep -f "$GLOBALS_FILE"
fi

if [ -n "$FUNCTIONS_FILE" ]; then
    echo -e "\nVerifying if there are any remaining functions from the one to be removed:"
    nm "$EXECUTABLE" | grep -f "$FUNCTIONS_FILE"
fi

echo -e "\nProcess completed. Backup saved as ${EXECUTABLE}.backup"
