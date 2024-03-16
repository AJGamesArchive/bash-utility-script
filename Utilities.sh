#!/bin/bash

# Enable for looping through subdirectorys within direcotrys with the /**/* syntax
shopt -s globstar

#? Log File Setup

# Setting up default _Directory file
_DIRECTORY="_Directory"

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
    return 0 # Returns 0 for process compelted
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
    return 0 # Returns 0 for process compelted
}

# Function to check for valid args count
expected_args() {
    local operator="$1"
    local expected_count="$2"
    case $operator in
        "<") # Less than
            if [ ${#args[@]} -gt $expected_count ]; then
                error 0 # Invalid args
                return 1 # Returns 1 for invalid args
            fi
            ;;
        ">") # Greater than
            if [ ${#args[@]} -lt $expected_count ]; then
                error 0 # Invalid args
                return 1 # Returns 1 for invalid args
            fi
            ;;
        *) # Equal to
            if [ ${#args[@]} -ne $expected_count ]; then
                error 0 # Invalid args
                return 1 # Returns 1 for invalid args
            fi
            ;;
    esac
    return 0 # Returns 0 for valid args
}

#? Command Utility Functions

# Function to count how many of each file types are present in as given directory
count_file_types() {
    # Variable to take in a file path as an arg
    local directory=$1
    # Loop through command args
    for arg in "${args[@]}"; do
        # Output results to log file AND terminal if arg is present
        if [ "$arg" == "-p" ]; then
            log "$LOG_INFO" "Counting occurence of all unique file types in $directory and outputting to terminal"
            echo "$directory/:"
            echo -e "$directory/:" >> "$LOG_FILE"
            find $directory -maxdepth 1 -type f | awk -F . '{print $NF}' | sort | uniq -c | tee -a "$LOG_FILE"
            return 0 # Returns 0 for process compelted
        fi
    done
    log "$LOG_INFO" "Counting occurence of all unique file types in $directory"
    echo -e "$directory/:" >> "$LOG_FILE"
    find $directory -maxdepth 1 -type f | awk -F . '{print $NF}' | sort | uniq -c >> "$LOG_FILE"
    return 0 # Returns 0 for process compelted
}

# Function to count collective size of each file type in _Directory
count_file_type_size() {
    # Variable to take in a file path as an arg
    local directory=$1
    log "$LOG_INFO" "Counting the collective file size for each unique file type in $directory"
    # Associative array/dictionary to store total size for each file type
    declare -A file_sizes
    # Loop through all files in the directory and its subdirectories
    for file in "$directory"/*; do
        if [ -f "$file" ]; then
            # Get the file extension
            extension="${file##*.}"
            # Get the size of the file
            size=$(stat -c %s "$file")
            # Add the size to the total for the corresponding file type
            file_sizes["$extension"]=$(( ${file_sizes["$extension"]} + size ))
        fi
    done
    # Convert total size from bytes to MB * 100
    # This number will be divided by 100 and formatted to 2 DP upon output using printf
    declare -A file_sizes_mb
    for extension in "${!file_sizes[@]}"; do
        file_sizes_mb["$extension"]=$(( (${file_sizes["$extension"]} * 100) / (1024 * 1024) ))
    done
    # Loop through all command args
    for arg in "${args[@]}"; do
        # Output results to log file AND terminal if arg is present
        if [ "$arg" == "-p" ]; then
            log "$LOG_INFO" "Printing results to terminal"
            echo "$directory/:"
            echo -e "$directory/:" >> "$LOG_FILE"
            # Print the total size for each file type to log file AND terminal
            for extension in "${!file_sizes[@]}"; do
                echo "Total size of '.$extension' files: ${file_sizes["$extension"]} bytes"
                echo -e "Total size of '.$extension' files: ${file_sizes["$extension"]} bytes" >> "$LOG_FILE"
                echo "Total size of '.$extension' files: $(( file_sizes_mb["$extension"] / 100 )).$(printf "%02d" $(( file_sizes_mb["$extension"] % 100 ))) MB"
                echo -e "Total size of '.$extension' files: $(( file_sizes_mb["$extension"] / 100 )).$(printf "%02d" $(( file_sizes_mb["$extension"] % 100 ))) MB" >> "$LOG_FILE"
            done
            return 0 # Returns 0 for process compelted
        fi
    done
    # Print the total size for each file type to log file
    echo -e "$directory/:" >> "$LOG_FILE"
    for extension in "${!file_sizes[@]}"; do
        echo -e "Total size of '.$extension' files: ${file_sizes["$extension"]} bytes" >> "$LOG_FILE"
        echo -e "Total size of '.$extension' files: $(( file_sizes_mb["$extension"] / 100 )).$(printf "%02d" $(( file_sizes_mb["$extension"] % 100 ))) MB" >> "$LOG_FILE"
    done
    return 0 # Returns 0 for process compelted
}

# Function to count the total collective space used in _Directory, in human readable format
count_total_space() {
    # Variable to take in a file path as an arg
    local directory=$1
    log "$LOG_INFO" "Calculating total file space used in $directory"
    # Variable to store total file size
    total_size=0
    for file in "$directory"/*; do
        if [ -f "$file" ]; then
            size=$(stat -c "%s" "$file")
            total_size=$((total_size + size))
        fi
    done
    # Convert total size from bytes to MB * 100
    # This number will be divided by 100 and formatted to 2 DP upon output using printf
    total_size_mb=$(( ($total_size * 100) / (1024 * 1024) ))
    # Loop through all command args
    for arg in "${args[@]}"; do
        # Output results to log file AND terminal if arg is present
        if [ "$arg" == "-p" ]; then
            log "$LOG_INFO" "Printing results to terminal"
            echo "Total space used by '$directory': $total_size bytes"
            echo "Total space used by '$directory': $(( total_size_mb / 100 )).$(printf "%02d" $(( total_size_mb % 100 ))) MB"
        fi
    done
    echo -e "Total space used by '$directory': $total_size bytes" >> "$LOG_FILE"
    echo -e "Total space used by '$directory': $(( total_size_mb / 100 )).$(printf "%02d" $(( total_size_mb % 100 ))) MB" >> "$LOG_FILE"
    return 0 # Return 0 for process complete
}

# Function to count and find the shortest or largest file name(s) in _Directory depending on given args
filename_search() {
    # Variable to take in a file path as an arg
    local directory=$1
    # Take in an arg for either shorest or largest file name search
    local operation="$2"
    # Declaring vairables to store file names and shortest langth
    local files=()
    case $operation in
        "shortest")
            local base_length=9999999999
            ;;
        "largest")
            local base_length=0
            ;;
        *)
            error 0 # Invalid args error
            return 1 # Return 1 for invalid args provided
            ;;
    esac
    # Loging process start
    log "$LOG_INFO" "Searching for the '$operation' file names and lengths in '$directory'"
    log "$LOG_INFO" "Counting filenames excluding directory file paths and file extentions"
    # Loop through all files in the directory and its subdirectories
    for file in "$directory"/*; do
        if [ -f "$file" ]; then
            # Get the file name without the directory path
            filename=$(basename "$file")
            # Remove the file extension from the file name
            filename_no_extension="${filename%.*}"
            # Get the length of the file name
            length=${#filename_no_extension}
            case $operation in
                "shortest")
                    # Update shortest length if current file name is shorter
                    if [ "$length" -lt "$base_length" ]; then
                        base_length="$length"
                        files=("$file")
                    fi
                    ;;
                "largest")
                    # Update longest length if current file name is longer
                    if [ "$length" -gt "$base_length" ]; then
                        base_length="$length"
                        files=("$file")
                    fi
                    ;;
            esac
            # Add file to array if it's file name is the same length as current target
            if [ "$length" -eq "$base_length" ]; then
                files+=("$file")
            fi
        fi
    done
    # If searching for shortest files and no files are found, set the base file lenght to 0
    if [ $base_length -eq 9999999999 ]; then
        base_length=0
    fi
    # Loop through all command args
    for arg in "${args[@]}"; do
        # Output results to log file AND terminal if arg is present
        if [ "$arg" == "-p" ]; then
            log "$LOG_INFO" "Printing results to terminal"
            echo "$operation file name length: $base_length"
            log "$LOG_INFO" "$operation file name length: $base_length"
            echo "${#files[@]} $operation file(s):"
            log "$LOG_INFO" "${#files[@]} $operation file(s):"
            echo "$directory/:"
            echo -e "$directory/:" >> "$LOG_FILE"
            for file in "${files[@]}"; do
                echo "$file"
                echo -e "$file" >> "$LOG_FILE"
            done
            return 0 # Returns 0 for process compelted
        fi
    done
    log "$LOG_INFO" "$operation file name length: $base_length"
    log "$LOG_INFO" "${#files[@]} $operation file(s):"
    echo -e "$directory/:" >> "$LOG_FILE"
    for file in "${files[@]}"; do
        echo -e "$file" >> "$LOG_FILE"
    done
    return 0 # Returns 0 for process compelted
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
                error 0 # Invalid args
                ;;
        esac
    done
    return 0 # Returns 0 for process compelted
}

#? Command Controller Functions

# Function to control the UUID command
uuid_controller() {
    # Ensure command has 2 args
    expected_args "=" 2
    if [ $? -eq 1 ]; then
        return 1
    fi
    # Check the second args for UUID generation
    case ${args[1]} in
        "-v1") # Generate version 1
            log "$LOG_INFO" "Executing Arg '${args[1]}'"
            UUID=$(uuidgen -t)
            echo "Generated UUID (version 1): $UUID"
            log "$LOG_INFO" "Generated UUID (version 1): $UUID"
            ;;
        "-v4") # Generate version 4
            log "$LOG_INFO" "Executing Arg '${args[1]}'"
            UUID=$(uuidgen)
            echo "Generated UUID (version 4): $UUID"
            log "$LOG_INFO" "Generated UUID (version 4): $UUID"
            ;;
        *)
            log "$LOG_INFO" "Executing Arg '${args[1]}'"
            error 0 # Invalid args
            ;;
    esac
    return 0 # Returns 0 for process compelted
}

# Function to control the evaldir command.
evaldir_controller() {
    # Ensure command has at least 2 args
    expected_args ">" 2
    if [ $? -eq 1 ]; then
        return 1
    fi
    log "$LOG_INFO" "Analyzing '$_DIRECTORY'"
    # Perform functions per argument given
    command_arg=true
    for arg in "${args[@]}"; do
        if [ $command_arg == true ]; then
            command_arg=false
            continue
        fi
        if [ "$arg" == "-p" ]; then
            continue
        fi
        log "$LOG_INFO" "Executing Arg '$arg'"
        # Count how many of each file types are present in the directory and all sub directoryies if arg is provided
        if [ "$arg" == "-ct" ]; then
            count_file_types "$_DIRECTORY"
            for file in $_DIRECTORY/**/*; do
                if [ -d "$file" ]; then
                    count_file_types "$file"
                fi
            done
            echo "File type counting complete"
            log "$LOG_INFO" "File type counting complete"
            continue
        fi
        # Count collective size of each file type in the directory if arg is provided
        if [ "$arg" == "-cts" ]; then
            count_file_type_size "$_DIRECTORY"
            for file in $_DIRECTORY/**/*; do
                if [ -d "$file" ]; then
                    count_file_type_size "$file"
                fi
            done
            echo "Collective file type size counting complete"
            log "$LOG_INFO" "Collective file type size counting complete"
            continue
        fi
        # Count the total space used, in human readable format, in the direcotry if arg is provided
        if [ "$arg" == "-t" ]; then
            count_total_space "$_DIRECTORY"
            for file in $_DIRECTORY/**/*; do
                if [ -d "$file" ]; then
                    count_total_space "$file"
                fi
            done
            echo "Total space calculated successfully"
            log "$LOG_INFO" "Total space calculated successfully"
            continue
        fi
        # Count and find the shortest file name(s) in directory if arg is provided
        if [ "$arg" == "-fs" ]; then
            filename_search "$_DIRECTORY" "shortest"
            for file in $_DIRECTORY/**/*; do
                if [ -d "$file" ]; then
                    filename_search "$file" "shortest"
                fi
            done
            echo "Shortest file name search complete"
            log "$LOG_INFO" "Shortest file name search complete"
            continue
        fi
        # Count and find the largest file name(s) in directory if arg is provided
        if [ "$arg" == "-fl" ]; then
            filename_search "$_DIRECTORY" "largest"
            for file in $_DIRECTORY/**/*; do
                if [ -d "$file" ]; then
                    filename_search "$file" "largest"
                fi
            done
            echo "Largest file name search complete"
            log "$LOG_INFO" "Largest file name search complete"
            continue
        fi
        log "$LOG_WARNING" "Arg '$arg' is invalid"
        log "$LOG_INFO" "Continueing to next arg"
        echo "WARNING: Arg '$arg' is invalid"
        echo "Continueing to next arg"
    done
    return 0 # Returns 0 for process compelted
}

# Function to control the log command
log_controller() {
    # Ensure command has 2 args
    expected_args "=" 2
    if [ $? -eq 1 ]; then
        return 1
    fi
    # Check the second args for log management
    case ${args[1]} in
        "-c") # Delete all previous log files
            log "$LOG_INFO" "Executing Arg '${args[1]}'"
            delete_old_logs
            ;;
        *)
            log "$LOG_INFO" "Executing Arg '${args[1]}'"
            error 0 # Invalid args
            ;;
    esac
    return 0 # Returns 0 for process compelted
}

# Function to control the help command
help_controller() {
    log "$LOG_ERROR" "MAN page not implemented yet"
    echo "ERROR: MAN page not implemented yet."
    return 0 # Returns 0 for process compelted
}

# Function to control the exit command
exit_controller() {
    # Ensure command has 2 args
    expected_args "=" 2
    if [ $? -eq 1 ]; then
        return 1
    fi
    # Check the second args for exit command
    case ${args[1]} in
        "-0") # Exit with code 0 - Process completed
            log "$LOG_INFO" "Executing Arg '${args[1]}'"
            log "$LOG_INFO" "Script exited with code 0"
            echo "Script Exiting... (0)"
            exit 0
            ;;
        "-1") # Exit with code 1 - Process failed
            log "$LOG_INFO" "Executing Arg '${args[1]}'"
            log "$LOG_ERROR" "Script exited with code 1"
            echo "Script Exiting... (1)"
            exit 1
            ;;
        *)
            log "$LOG_INFO" "Executing Arg '${args[1]}'"
            error 0 # Invalid args
            ;;
    esac
    return 0 # Returns 0 for process compelted
}

#? Script Login

# Loggin start of script
log "$LOG_INFO" "Script Started"
echo "Script Started"

# Login to the system
read -p "Enter your name to login: " -a args
log "$LOG_INFO" "${args[@]} has logged in"
log "$LOG_INFO" "Listing machine user details \n$(w -s)"

#? Main Menu Loop

echo "Utility Script";
echo "'uuid' - Generate a UUID [-v1, -v4]"
echo "'evaldir' - Evalulate '_Directory' [-ct, -cts, -t, -fs, -fl, -p]"
echo "'log' - Manage Log Files [-c]"
echo "'help' - Open MAN Page"
echo "'exit' - Exit Script [-0, -1]"

# Script Main Menu
while true; do
    # Promped the user to select a utility
    echo "Select a utility:"
    read -p ": " -a args
    log "$LOG_INFO" "Command executed: '${args[@]}'"
    # Check the first argument provided
    case ${args[0]} in 
        "uuid" | "id")
            uuid_controller
            ;;
        "evaldir" | "ed")
            evaldir_controller
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
