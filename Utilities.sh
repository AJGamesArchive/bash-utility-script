#!/bin/bash

# Setup a file to append logs to
CURRENT_DATE=$(date +"%Y-%m-%d %H:%M:%S")
LOG_DIR="_Logs"
LOG_FILE="$LOG_DIR/Logs_$CURRENT_DATE.log"
mkdir -p $LOG_DIR

# Log Variables
LOG_INFO="INFO"
LOG_WARNING="WARNING"
LOG_ERROR="ERROR"

# Function to log messages
log() {
    local state="$1"
    local message="${@:2}"
    echo "$(date +"%Y-%m-%d %H:%M:%S") - [$state] $message" >> "$LOG_FILE"
}

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
                echo "Invalid Args. See the MAN page for help."
                log "$LOG_INFO" "Invalid Args. See the MAN page for help."
                ;;
        esac
    done
}

# Loggin start of script
log "$LOG_INFO" "Script Started"
echo "Script Started"

# Login to the system
read -p "Enter your name to login: " -a args
log "$LOG_INFO" "${args[@]} has logged in"
echo "Utility Script";

# Script Main Menu
while true; do
    # Promped the user to select a utility
    echo "Select a utility:"
    echo "'uuid' - Generate a UUID [-v1, -v4]"
    echo "'log' - Manage Log Files [-c]"
    echo "'help' - Open MAN Page [-0, -1]"
    echo "'e' - Exit Script [-0, -1]"
    read -p ": " -a args
    log "$LOG_INFO" "Command executed: ${args[@]}"

    # Check that the correct number of arguments has been provided 
    if [ ${#args[@]} -ne 2 ]; then
        echo "Invalid Args. See the MAN page for help."
        log "$LOG_ERROR" "Invalid Args. See the MAN page for help."
        continue
    fi

    # Check the first argument provided
    case ${args[0]} in 
        "uuid")
            # Check the second args for UUID generation
            case ${args[1]} in
                "-v1")
                    UUID=$(uuidgen -t)
                    echo "Generated UUID (version 1): $UUID"
                    log "$LOG_INFO" "Generated UUID (version 1): $UUID"
                    ;;
                "-v4")
                    UUID=$(uuidgen)
                    echo "Generated UUID (version 4): $UUID"
                    log "$LOG_INFO" "Generated UUID (version 4): $UUID"
                    ;;
                *)
                    echo "Invalid UUID Version. See the MAN page for help"
                    log "$LOG_ERROR" "Invalid Args. See the MAN page for help."
                    ;;
            esac
            ;;
        "e")
            case ${args[1]} in
                "-0")
                    log "$LOG_INFO" "Script exited with code 0"
                    echo "Script Exiting... (0)"
                    exit 0
                    ;;
                "-1")
                    log "$LOG_ERROR" "Script exited with code 1"
                    echo "Script Exiting... (1)"
                    exit 1
                    ;;
                *)
                    echo "Invalid Args. See the MAN page for help."
                    log "$LOG_ERROR" "Invalid Args. See the MAN page for help."
                    ;;
            esac
            ;;
        "log")
            case ${args[1]} in
                # Delete all previous log files
                "-c")
                    delete_old_logs
                    ;;
                *)
                    echo "Invalid Args. See the MAN page for help."
                    log "$LOG_ERROR" "Invalid Args. See the MAN page for help."
                    ;;
            esac
            ;;
        "help")
            log "$LOG_ERROR" "MAN page not implemented yet"
            echo "ERROR: MAN page not implemented yet."
            ;;
        *)
            echo "Invalid Args. See the MAN page for help."
            log "$LOG_ERROR" "Invalid Args. See the MAN page for help."
            ;;
    esac
done

log "$LOG_INFO" "Script exited with code 0"
echo "Script Exiting... (0)"
exit 0