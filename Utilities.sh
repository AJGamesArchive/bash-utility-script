#!/bin/bash

#? Log File Setup

# Setup a file to append logs to
CURRENT_DATE=$(date +"%Y-%m-%d %H:%M:%S")
LOG_DIR="_Logs"
LOG_FILE="$LOG_DIR/Logs_$CURRENT_DATE.log"
mkdir -p $LOG_DIR

# Log Variables
LOG_INFO="INFO"
LOG_WARNING="WARNING"
LOG_ERROR="ERROR"

#? Core Process Functions

# Function to log messages
log() {
    local state="$1"
    local message="${@:2}"
    echo -e "$(date +"%Y-%m-%d %H:%M:%S") - [$state] $message" >> "$LOG_FILE"
}

# Function to log common errors
error() {
    local code="$@"
    case $code in
        "0")
            echo "Invalid Args. Run 'help' for details on commands and args."
            log "$LOG_ERROR" "Invalid Args. Run 'help' for details on commands and args."
            ;;
        "1")
            echo "Command '$args' does not exist. Run 'help' for details on commands and args."
            log "$LOG_ERROR" "Command '$args' does not exist. Run 'help' for details on commands and args."
            ;;
    esac
}

# Function to check for valid args count
expected_args() {
    local expected_count="$@"
    if [ ${#args[@]} -ne $expected_count ]; then
        error 0 # Invalid args
        return 1 # Returns 1 for invalid args
    fi
    return 0 # Returns 0 for valid args
}

#? Command Utility Functions

# Function to delete all old log files
delete_old_logs() {
    # Log all files that will be deleted
    log "$LOG_INFO" "Listing all files that will be deleted"
    echo "Listing all files that will be deleted"
    ls --ignore="Logs_$CURRENT_DATE.log" $LOG_DIR >> "$LOG_FILE"
    ls --ignore="Logs_$CURRENT_DATE.log" $LOG_DIR

    # Count the number of files being deleted
    FILE_COUNT=$(ls --ignore="Logs_$CURRENT_DATE.log" $LOG_DIR | wc -l)
    log "$LOG_INFO" "Total number of files being deleted: $FILE_COUNT"
    echo "Total number of files being deleted: $FILE_COUNT"

    # Confirming deletion 
    log "$LOG_WARNING" "Files are about to be deleted"
    echo "WARNING: Files are about to be deleted"
    while true; do
        read -p "Confirm deletion? (y/n): " -a args
        case ${args[0]} in
            "y")
                # Delete all previous log files
                log "$LOG_INFO" "Deletion confirmed. Deleting $FILE_COUNT files..."
                find $LOG_DIR/ ! -name "Logs_$CURRENT_DATE.log" -type f -exec rm {} +
                echo "$FILE_COUNT files deleted"
                log "$LOG_INFO" "$FILE_COUNT files deleted"
                break;
                ;;
            "n")
                # Aborting deletion process
                echo "Aborting process. No files were deleted."
                log "$LOG_INFO" "Aborting process. No files were deleted"
                break;
                ;;
            *)
                error 0 # Invalid args
                ;;
        esac
    done
}

#? Command Controller Functions

# Function to control the UUID command
uuid_controller() {
    # Ensure command has 2 args
    expected_args 2
    if [ $? -eq 1 ]; then
        return 1
    fi
    # Check the second args for UUID generation
    case ${args[1]} in
        "-v1") # Generate version 1
            UUID=$(uuidgen -t)
            echo "Generated UUID (version 1): $UUID"
            log "$LOG_INFO" "Generated UUID (version 1): $UUID"
            ;;
        "-v4") # Generate version 4
            UUID=$(uuidgen)
            echo "Generated UUID (version 4): $UUID"
            log "$LOG_INFO" "Generated UUID (version 4): $UUID"
            ;;
        *)
            error 0 # Invalid args
            ;;
    esac
}

# Function to control the log command
log_controller() {
    # Ensure command has 2 args
    expected_args 2
    if [ $? -eq 1 ]; then
        return 1
    fi
    # Check the second args for log management
    case ${args[1]} in
        "-c") # Delete all previous log files
            delete_old_logs
            ;;
        *)
            error 0 # Invalid args
            ;;
    esac
}

# Function to control the help command
help_controller() {
    log "$LOG_ERROR" "MAN page not implemented yet"
    echo "ERROR: MAN page not implemented yet."
}

# Function to control the exit command
exit_controller() {
    # Ensure command has 2 args
    expected_args 2
    if [ $? -eq 1 ]; then
        return 1
    fi
    # Check the second args for exit command
    case ${args[1]} in
        "-0") # Exit with code 0 - Process completed
            log "$LOG_INFO" "Script exited with code 0"
            echo "Script Exiting... (0)"
            exit 0
            ;;
        "-1") # Exit with code 1 - Process failed
            log "$LOG_ERROR" "Script exited with code 1"
            echo "Script Exiting... (1)"
            exit 1
            ;;
        *)
            error 0 # Invalid args
            ;;
    esac
}

#? Script Login

# Loggin start of script
log "$LOG_INFO" "Script Started"
echo "Script Started"

# Login to the system
read -p "Enter your name to login: " -a args
log "$LOG_INFO" "${args[@]} has logged in"
log "$LOG_INFO" "Listing machine User details \n$(w -s)"

#? Main Menu Loop

echo "Utility Script";

# Script Main Menu
while true; do
    # Promped the user to select a utility
    echo "Select a utility:"
    echo "'uuid' - Generate a UUID [-v1, -v4]"
    echo "'log' - Manage Log Files [-c]"
    echo "'help' - Open MAN Page"
    echo "'exit' - Exit Script [-0, -1]"
    read -p ": " -a args
    log "$LOG_INFO" "Command executed: '${args[@]}'"

    # Check the first argument provided
    case ${args[0]} in 
        "uuid" | "id")
            uuid_controller
            ;;
        "exit" | "e")
            exit_controller
            ;;
        "log" | "l")
            log_controller
            ;;
        "help" | "h")
            help_controller
            ;;
        *)
            error 1 # Command does not exist
            ;;
    esac
done
