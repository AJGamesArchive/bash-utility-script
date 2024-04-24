#!/bin/bash

#? Setup initial script settings

# Save all arguments into the 'args' array
args=("$@")

# Enable for looping through subdirectorys within direcotrys with the /**/* syntax
shopt -s globstar

#? Log File Setup

# Setting up default UUID output file
UUID_DIR="UUID_Output"
mkdir -p $UUID_DIR
UUID_FILE="$UUID_DIR/UUIDs.txt"

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

# Function to check what option args of the 'evaldir' command are present
check_evaldir_optional_args() {
    # Variables to store optional arg states
    local print_to_terminal=false
    local output_collective=false
    # Loop through command args to search for option args
    for arg in "${args[@]}"; do
        if [ "$arg" == "-p" ]; then
            print_to_terminal=true
        fi 
        if [ "$arg" == "-o" ]; then
            output_collective=true
        fi
    done
    # Return different codes depending on what args are present
    if [ $print_to_terminal == true ] && [ $output_collective == true ]; then
        return 4 # BOTH optional args are present
    fi
    if [ $output_collective == true ]; then
        return 3 # ONLY -o is present
    fi
    if [ $print_to_terminal == true ]; then
        return 2 # ONLY -p is present
    fi
    return 1 # NO optional args are present
}

# Function to check whether file extentions should be excluded from the filename length searcher
check_remove_extention() {
    # Loop through command args to search for option args
    for arg in "${args[@]}"; do
        if [ "$arg" == "-re" ]; then
            return 0 # Return 0 for remove extention
        fi
    done
    return 1 # Return 1 for don't remove extention
}

#? Command Utility Functions

# Function to check for UUID generation collisions
uuid_collision_checker() {
    local version=$1
    log "$LOG_INFO" "Checking for UUID V$version collisions"
    # Take in arg for the newly generated UUID
    local new_uuid=$2
    # Check UUID file to see if UUID already exists
    if grep -q "$new_uuid" $UUID_FILE; then
        line_number=$(grep -n "$new_uuid" $UUID_FILE | cut -d ':' -f 1)
        log "$LOG_WARNING" "UUID V$version Collision found on line '$line_number' in '$UUID_FILE'"
        log "$LOG_WARNING" "The duplicate UUID will not be saved"
        return 1 # Collision occured
    fi
    log "$LOG_INFO" "No UUID V$version collisions found"
    # Save new UUID to UUID file
    echo -e "[$(date +"%Y-%m-%d %H:%M:%S")] $new_uuid" >> "$UUID_FILE"
    log "$LOG_INFO" "UUID V$version saved to '$UUID_FILE'"
    return 0 # NO collision occured
}

# Function to check what the last UUID generated was and when it was generated
check_last_uuid() {
    log "$LOG_INFO" "Search for last generated UUID"
    # Search for most recent UUID and output to log file
    echo -e "UUID Found: $(grep -v '^$' $UUID_FILE | tail -n 1)" >> "$LOG_FILE"
    # Output to terminal if arg is present
    for arg in "${args[@]}"; do
        if [ "$arg" == "-p" ]; then
            log "$LOG_INFO" "Printing to terminal"
            echo "UUID Found: $(grep -v '^$' $UUID_FILE | tail -n 1)"
        fi
    done
    log "$LOG_INFO" "Search Complete"
    return 0 # Process completed successfully
}

# Function to generate a UUID Versioon 1
uuid_version_1() {
    log "$LOG_INFO" "Generating version 1 (time based)"
    # Set version to 1 (time-based)
    version=1
    # Get the current time in 100-nanosecond intervals since 1582-10-15 00:00:00 UTC
    current_time=$(date -u +%s)
    timestamp=$(($current_time * 10000000 + 0x01B21DD213814000))
    # Convert time to hex and add padding if needed
    timestamp_hex=$(printf "%016x" $timestamp)
    # Split the hexed time into segments (low, mid, hi)
    time_low=${timestamp_hex:8:8}
    time_mid=${timestamp_hex:4:4}
    time_hi=${timestamp_hex:1:3}
    # Generate clock sequence (14 random bits)
    clock_sequence=$(od -A n -t x2 -N 2 /dev/urandom | tr -d ' ')
    # Generate node ID (48 random bits)
    node_id=$(od -A n -t x8 -N 6 /dev/urandom | tr -d ' ')
    # Format the UUID
    uuid="$time_low-$time_mid-$version$time_hi-$clock_sequence-${node_id:4:2}${node_id:6:2}${node_id:8:2}${node_id:10:2}${node_id:12:2}${node_id:14:2}"
    # Output UUID
    log "$LOG_INFO" "UUID V1: $uuid"
    # Check for collisions
    uuid_collision_checker 1 "$uuid" &
    log "$LOG_INFO" "Process Run:" $!
    wait
    if [ $? -eq 1 ]; then
        echo "UUID V$version generation unsuccessful. Collision found."
        log "$LOG_INFO" "UUID V$version generation unsuccessful. Collision found."
        return 1 # Collision found
    fi
    # Output UUID to terminal if arg is present and if generation is successful
    for arg in "${args[@]}"; do
        if [ "$arg" == "-p" ]; then
            log "$LOG_INFO" "Printing to terminal"
            echo "UUID V1: $uuid"
        fi
    done
    log "$LOG_INFO" "UUID V$version generation successful"
    return 0 # Process completed successfully
}

# Function to generate a UUID Versioon 4
uuid_version_4() {
    log "$LOG_INFO" "Generating version 4 (pseudo-random)"
    # Set version to version 4 (pseudo-random)
    version=4
    # Set the varient of the uuid
    characters=("8" "9" "A" "B")
    index=$((RANDOM % ${#characters[@]}))
    varient=${characters[$index]}
    # Generate pseudo-random hex characters to fill the uuid
    first_32_bits=$(od -A n -t x2 -N 4 /dev/urandom | tr -d ' ')
    second_16_bits=$(od -A n -t x2 -N 2 /dev/urandom | tr -d ' ')
    third_16_bits=$(od -A n -t x2 -N 2 /dev/urandom | tr -d ' ')
    forth_16_bits=$(od -A n -t x2 -N 2 /dev/urandom | tr -d ' ')
    fitch_48_bits=$(od -A n -t x2 -N 6 /dev/urandom | tr -d ' ')
    # Put the uuid together
    uuid="$first_32_bits-$second_16_bits-$version${third_16_bits:1:3}-$varient${forth_16_bits:1:3}-$fitch_48_bits"
    # Output UUID
    log "$LOG_INFO" "UUID V4: $uuid"
    # Check for collisions
    uuid_collision_checker 4 "$uuid" &
    log "$LOG_INFO" "Process Run:" $!
    wait
    if [ $? -eq 1 ]; then
        echo "UUID V$version generation unsuccessful. Collision found."
        log "$LOG_INFO" "UUID V$version generation unsuccessful. Collision found."
        return 1 # Collision found
    fi
    # Output UUID to terminal if arg is present
    for arg in "${args[@]}"; do
        if [ "$arg" == "-p" ]; then
            log "$LOG_INFO" "Printing to terminal"
            echo "UUID V4: $uuid"
        fi
    done
    log "$LOG_INFO" "UUID V$version generation successful"
    return 0 # Process completed successfully
}

# Function to count how many of each file types are present in as given directory
count_file_types() {
    # Variable to take in a file path as an arg
    local directory=$1
    # Variables to store optional arg states
    local optional_args=$2
    # Variable to store if detailed mode has been called
    local detailed=$3
    # Log process action
    log "$LOG_INFO" "Counting occurence of all unique file types in $directory"
    if [ "$detailed" == "true" ]; then
        log "$LOG_INFO" "Counting by detailed file types"
    fi
    # Calculate collectively and output to terminal if args are present
    if [ $optional_args -eq 4 ]; then
        log "$LOG_INFO" "Counting files in all subdirectory's"
        log "$LOG_INFO" "Outputting to terminal"
        echo "$directory/**/*:"
        echo -e "$directory/**/*:" >> "$LOG_FILE"
        if [ "$detailed" == "true" ]; then
            # Use find to recursively list all files in the directory and its subdirectories
            files=$(find $directory -type f)
            # Loop through each file and extract its type using the file command
            file_types=$(for file in $files; do file "$file"; done)
            # Use grep to extract the file type from the output of the file command
            # Then use awk to count occurrences of each unique file type
            echo "$file_types" | grep -oP ':\s*\K.*' | awk '{count[$1]++} END {for (type in count) print type ": " count[type]}' | tee -a "$LOG_FILE"
            return 0 # Process completed successfully
        fi
        find $directory -type f | awk -F . '{print $NF}' | sort | uniq -c | tee -a "$LOG_FILE"
        return 0 # Process completed successfully
    fi
    # Calculate collectively if arg is present
    if [ $optional_args -eq 3 ]; then
        log "$LOG_INFO" "Counting files in all subdirectory's"
        echo -e "$directory/**/*:" >> "$LOG_FILE"
        if [ "$detailed" == "true" ]; then
            # Use find to recursively list all files in the directory and its subdirectories
            files=$(find $directory -type f)
            # Loop through each file and extract its type using the file command
            file_types=$(for file in $files; do file "$file"; done)
            # Use grep to extract the file type from the output of the file command
            # Then use awk to count occurrences of each unique file type
            echo -e "$file_types" | grep -oP ':\s*\K.*' | awk '{count[$1]++} END {for (type in count) print type ": " count[type]}' >> "$LOG_FILE"
            return 0 # Process completed successfully
        fi
        find $directory -type f | awk -F . '{print $NF}' | sort | uniq -c >> "$LOG_FILE"
        return 0 # Process completed successfully
    fi
    # Outputting to terminal if arg is resent
    if [ $optional_args -eq 2 ]; then
        log "$LOG_INFO" "Outputting to terminal"
        echo "$directory/:"
        echo -e "$directory/:" >> "$LOG_FILE"
        if [ "$detailed" == "true" ]; then
            # Get the list of all files in the directory
            files=$(find $directory -maxdepth 1 -type f)
            # Loop through each file and extract its type using the file command
            file_types=$(for file in $files; do file "$file"; done)
            # Use grep to extract the file type from the output of the file command
            # Then use awk to count occurrences of each unique file type
            echo "$file_types" | grep -oP ':\s*\K.*' | awk '{count[$1]++} END {for (type in count) print type ": " count[type]}' | tee -a "$LOG_FILE"
            return 0 # Process completed successfully
        fi
        find $directory -maxdepth 1 -type f | awk -F . '{print $NF}' | sort | uniq -c | tee -a "$LOG_FILE"
        return 0 # Process completed successfully
    fi
    echo -e "$directory/:" >> "$LOG_FILE"
    if [ "$detailed" == "true" ]; then
        # Get the list of all files in the directory
        files=$(find $directory -maxdepth 1 -type f)
        # Loop through each file and extract its type using the file command
        file_types=$(for file in $files; do file "$file"; done)
        # Use grep to extract the file type from the output of the file command
        # Then use awk to count occurrences of each unique file type
        echo -e "$file_types" | grep -oP ':\s*\K.*' | awk '{count[$1]++} END {for (type in count) print type ": " count[type]}' >> "$LOG_FILE"
        return 0 # Process completed successfully
    fi
    find $directory -maxdepth 1 -type f | awk -F . '{print $NF}' | sort | uniq -c >> "$LOG_FILE"
    return 0 # Returns 0 for process compelted
}

# Function to handle the file type counter modes
count_file_types_handler() {
    # Variable to take in a file path as an arg
    local directory=$1
    # Variables to sore optional arg states
    local optional_args=$2
    # Variable to store whether detailed mode has been called
    local detailed=false
    # Loop through command args to see if detailed mode was called
    for arg in "${args[@]}"; do
        if [ "$arg" == "-d" ]; then
            detailed=true
            break
        fi
    done
    # Call file type counter
    count_file_types "$directory" "$optional_args" "$detailed"
    return 0 # Returns 0 for process completed
}

# Function to count collective size of each file type in _Directory
count_file_type_size() {
    # Variable to take in a file path as an arg
    local directory=$1
    log "$LOG_INFO" "Counting the collective file size for each unique file type in $directory"
    # Variables to sore optional arg states
    local optional_args=$2
    # Variable to store whether detailed mode has been called
    local detailed=$3
    # Associative array/dictionary to store total size for each file type
    declare -A file_sizes
    # Loop through all files in the directory, include subdirectory's if arg is present
    if [ $optional_args -eq 3 ] || [ $optional_args -eq 4 ]; then
        log "$LOG_INFO" "Counting the collective file size for each unique file in all subdirectory's"
        for file in "$directory"/**/*; do
            if [ -f "$file" ]; then
                # Get the file extension
                local extension
                if [ $detailed == "true" ]; then
                    extension="$(file "$file" | grep -oP ':\s*\K.*')" # Detailed file type
                else
                    extension="${file##*.}"
                fi
                # Get the size of the file
                size=$(stat -c %s "$file")
                # Add the size to the total for the corresponding file type
                file_sizes["$extension"]=$(( ${file_sizes["$extension"]} + size ))
            fi
        done
    else
        for file in "$directory"/*; do
            if [ -f "$file" ]; then
                # Get the file extension
                local extension
                if [ $detailed == "true" ]; then
                    extension="$(file "$file" | grep -oP ':\s*\K.*')" # Detailed file type
                else
                    extension="${file##*.}"
                fi
                # Get the size of the file
                size=$(stat -c %s "$file")
                # Add the size to the total for the corresponding file type
                file_sizes["$extension"]=$(( ${file_sizes["$extension"]} + size ))
            fi
        done
    fi
    # Convert total size from bytes to KB * 100
    # This number will be divided by 100 and formatted to 2 DP upon output using printf
    declare -A file_sizes_kb
    for extension in "${!file_sizes[@]}"; do
        file_sizes_kb["$extension"]=$(( (${file_sizes["$extension"]} * 100) / 1024 ))
    done
    # Output results
    echo -e "$directory/:" >> "$LOG_FILE"
    for extension in "${!file_sizes[@]}"; do
        echo -e "Total size of '.$extension' files: ${file_sizes["$extension"]} bytes" >> "$LOG_FILE"
        echo -e "Total size of '.$extension' files: $(( file_sizes_kb["$extension"] / 100 )).$(printf "%02d" $(( file_sizes_kb["$extension"] % 100 ))) KB" >> "$LOG_FILE"
    done
    # Output to terminal if arg is present
    if [ $optional_args -eq 2 ] || [ $optional_args -eq 4 ]; then
        log "$LOG_INFO" "Printing results to terminal"
        echo "$directory/:"
        # Print the total size for each file type to terminal
        for extension in "${!file_sizes[@]}"; do
            echo "Total size of '.$extension' files: ${file_sizes["$extension"]} bytes"
            echo "Total size of '.$extension' files: $(( file_sizes_kb["$extension"] / 100 )).$(printf "%02d" $(( file_sizes_kb["$extension"] % 100 ))) KB"
        done
    fi
    return 0 # Returns 0 for process compelted
}

# Function to handle the file type size calculator modes
count_file_type_size_handler() {
    # Variable to take in a file path as an arg
    local directory=$1
    # Variables to store optional arg states
    local optional_args=$2
    # Variable to store whether detailed mode has been called
    local detailed=false
    # Loop through command args to see if detailed mode was called
    for arg in "${args[@]}"; do
        if [ "$arg" == "-d" ]; then
            detailed=true
            break
        fi
    done
    # Call file type size calculator
    count_file_type_size "$directory" "$optional_args" "$detailed"
    return 0 # Returns 0 for process completed
}

# Function to count the total collective space used in _Directory, in human readable format
count_total_space() {
    # Variable to take in a file path as an arg
    local directory=$1
    log "$LOG_INFO" "Calculating total file space used in $directory"
    # Variables to sore optional arg states
    local optional_args=$2
    # Variable to store total file size
    total_size=0
    # Loop through all files in the directory, include subdirectory's if arg is present
    if [ $optional_args -eq 3 ] || [ $optional_args -eq 4 ]; then
        log "$LOG_INFO" "Calculating total file space used in all subdirectory's"
        for file in "$directory"/**/*; do
            if [ -f "$file" ]; then
                size=$(stat -c "%s" "$file")
                total_size=$((total_size + size))
            fi
        done
    else
        for file in "$directory"/*; do
            if [ -f "$file" ]; then
                size=$(stat -c "%s" "$file")
                total_size=$((total_size + size))
            fi
        done
    fi
    # Convert total size from bytes to MB * 100
    # This number will be divided by 100 and formatted to 2 DP upon output using printf
    total_size_mb=$(( ($total_size * 100) / (1024 * 1024) ))
    # Output results
    echo -e "Total space used by '$directory': $total_size bytes" >> "$LOG_FILE"
    echo -e "Total space used by '$directory': $(( total_size_mb / 100 )).$(printf "%02d" $(( total_size_mb % 100 ))) MB" >> "$LOG_FILE"
    # Output to terminal if arg is present
    if [ $optional_args -eq 2 ] || [ $optional_args -eq 4 ]; then
        log "$LOG_INFO" "Printing results to terminal"
        echo "Total space used by '$directory': $total_size bytes"
        echo "Total space used by '$directory': $(( total_size_mb / 100 )).$(printf "%02d" $(( total_size_mb % 100 ))) MB"
    fi
    return 0 # Return 0 for process complete
}

# Function to count and find the shortest or largest file name(s) in _Directory depending on given args
filename_search() {
    # Variable to take in a file path as an arg
    local directory=$1
    # Take in an arg for either shorest or largest file name search
    local operation="$2"
    # Variables to sore optional arg states
    local optional_args=$3
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
    log "$LOG_INFO" "Counting filenames excluding directory file paths"
    # Check if the file extention should be excluded from the file name length
    local exclude_extention=false
    check_remove_extention
    if [ $? -eq 0 ]; then
        log "$LOG_INFO" "Counting filenames excluding file extention"
        exclude_extention=true
    fi
    # Loop through all files in the directory, including subdirectory's if arg is present
    if [ $optional_args -eq 3 ] || [ $optional_args -eq 4 ]; then
        log "$LOG_INFO" "Searching for the '$operation' file names and lengths in all subdirectory's"
        for file in "$directory"/**/*; do
            if [ -f "$file" ]; then
                # Get the file name without the directory path
                filename=$(basename "$file")
                # Remove file extention from filename if optional arg is resent
                if [ $exclude_extention == true ]; then
                    filename="${filename%.*}"
                fi
                # Get the length of the file name
                length=${#filename}
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
    else
        for file in "$directory"/*; do
            if [ -f "$file" ]; then
                # Get the file name without the directory path
                filename=$(basename "$file")
                # Remove file extention from filename if optional arg is resent
                if [ $exclude_extention == true ]; then
                    filename="${filename%.*}"
                fi
                # Get the length of the file name
                length=${#filename}
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
    fi
    # If searching for shortest files and no files are found, set the base file lenght to 0
    if [ $base_length -eq 9999999999 ]; then
        base_length=0
    fi
    # Outputting results
    log "$LOG_INFO" "$operation file name length: $base_length"
    log "$LOG_INFO" "${#files[@]} $operation file(s):"
    echo -e "$directory/:" >> "$LOG_FILE"
    for file in "${files[@]}"; do
        echo -e "$file" >> "$LOG_FILE"
    done
    # Output to terminal if arg is present
    if [ $optional_args -eq 2 ] || [ $optional_args -eq 4 ]; then
        log "$LOG_INFO" "Printing results to terminal"
        echo "$operation file name length: $base_length"
        echo "${#files[@]} $operation file(s):"
        echo "$directory/:"
        for file in "${files[@]}"; do
            echo "$file"
        done
    fi
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
    file_count=$(ls --ignore="Logs_$CURRENT_DATE.log" $LOG_DIR | wc -l)
    log "$LOG_INFO" "Total number of files being deleted: $file_count"
    echo "Total number of files being deleted: $file_count"
    # Confirming deletion 
    log "$LOG_WARNING" "Files are about to be deleted"
    echo "WARNING: Files are about to be deleted"
    while true; do
        read -p "Confirm deletion? (y/n): " -a args
        case ${args[0]} in
            "y")
                # Delete all previous log files
                log "$LOG_INFO" "Deletion confirmed. Deleting $file_count files..."
                find $LOG_DIR/ ! -name "Logs_$CURRENT_DATE.log" -type f -exec rm {} +
                echo "$file_count files deleted"
                log "$LOG_INFO" "$file_count files deleted"
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
    # Ensure command has at least 2 args
    expected_args ">" 2 &
    log "$LOG_INFO" "Process Run:" $!
    wait
    if [ $? -eq 1 ]; then
        return 1
    fi
    # Perform functions per argument given
    command_arg=true
    for arg in "${args[@]}"; do
        # If statements to ignore the command arg and optional output args
        if [ $command_arg == true ]; then
            command_arg=false
            continue
        fi
        if [ "$arg" == "-p" ]; then
            continue
        fi
        log "$LOG_INFO" "Executing Arg '$arg'"
        # Generate a version 1 UUID (time based) if arg is present
        if [ "$arg" == "-t" ]; then
            uuid_version_1 &
            log "$LOG_INFO" "Process Run:" $!
            continue
        fi
        # Generate a version 4 UUID (pseudo-random) if arg is present
        if [ "$arg" == "-pr" ]; then
            uuid_version_4 &
            log "$LOG_INFO" "Process Run:" $!
            continue
        fi
        # Check what the last UUID generated was and when it was generated if arg is present
        if [ "$arg" == "-ch" ]; then
            check_last_uuid &
            log "$LOG_INFO" "Process Run:" $!
            continue
        fi
        # Log invalid args
        log "$LOG_WARNING" "Arg '$arg' is invalid"
        log "$LOG_INFO" "Continueing to next arg"
        echo "WARNING: Arg '$arg' is invalid"
        echo "Continueing to next arg"
    done
    wait
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
    # Variables to sore optional arg states
    check_evaldir_optional_args
    local optional_args=$?
    # Perform functions per argument given
    command_arg=true
    for arg in "${args[@]}"; do
        # If statements to ignore the command arg and optional output args
        if [ $command_arg == true ]; then
            command_arg=false
            continue
        fi
        if [ "$arg" == "-p" ]; then
            continue
        fi
        if [ "$arg" == "-o" ]; then
            continue
        fi
        if [ "$arg" == "-d" ]; then
            continue
        fi
        if [ "$arg" == "-re" ]; then
            continue
        fi
        log "$LOG_INFO" "Executing Arg '$arg'"
        # Count how many of each file types are present in the directory and all sub directoryies if arg is provided
        if [ "$arg" == "-ct" ]; then
            count_file_types_handler "$_DIRECTORY" "$optional_args"
            if [ $optional_args -ne 3 ] && [ $optional_args -ne 4 ]; then
                for file in $_DIRECTORY/**/*; do
                    if [ -d "$file" ]; then
                        count_file_types_handler "$file" "$optional_args"
                    fi
                done
            fi
            echo "File type counting complete"
            log "$LOG_INFO" "File type counting complete"
            continue
        fi
        # Count collective size of each file type in the directory if arg is provided
        if [ "$arg" == "-cts" ]; then
            count_file_type_size_handler "$_DIRECTORY" "$optional_args"
            if [ $optional_args -ne 3 ] && [ $optional_args -ne 4 ]; then
                for file in $_DIRECTORY/**/*; do
                    if [ -d "$file" ]; then
                        count_file_type_size_handler "$file" "$optional_args"
                    fi
                done
            fi
            echo "Collective file type size counting complete"
            log "$LOG_INFO" "Collective file type size counting complete"
            continue
        fi
        # Count the total space used, in human readable format, in the direcotry if arg is provided
        if [ "$arg" == "-t" ]; then
            count_total_space "$_DIRECTORY" "$optional_args"
            if [ $optional_args -ne 3 ] && [ $optional_args -ne 4 ]; then
                for file in $_DIRECTORY/**/*; do
                    if [ -d "$file" ]; then
                        count_total_space "$file" "$optional_args"
                    fi
                done
            fi
            echo "Total space calculated successfully"
            log "$LOG_INFO" "Total space calculated successfully"
            continue
        fi
        # Count and find the shortest file name(s) in directory if arg is provided
        if [ "$arg" == "-fs" ]; then
            filename_search "$_DIRECTORY" "shortest" "$optional_args"
            if [ $optional_args -ne 3 ] && [ $optional_args -ne 4 ]; then
                for file in $_DIRECTORY/**/*; do
                    if [ -d "$file" ]; then
                        filename_search "$file" "shortest" "$optional_args"
                    fi
                done
            fi
            echo "Shortest file name search complete"
            log "$LOG_INFO" "Shortest file name search complete"
            continue
        fi
        # Count and find the largest file name(s) in directory if arg is provided
        if [ "$arg" == "-fl" ]; then
            filename_search "$_DIRECTORY" "largest" "$optional_args"
            if [ $optional_args -ne 3 ] && [ $optional_args -ne 4 ]; then
                for file in $_DIRECTORY/**/*; do
                    if [ -d "$file" ]; then
                        filename_search "$file" "largest" "$optional_args"
                    fi
                done
            fi
            echo "Largest file name search complete"
            log "$LOG_INFO" "Largest file name search complete"
            continue
        fi
        # Log invalid args
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
    log "$LOG_INFO" "List of commands and args outputted to terminal"
    echo "Utility Script:";
    echo "Command, Alt      - Description               - Required Arg(s)               - Optional Args";
    echo "'uuid, id'        - Generate a UUID           - [-ch, -t, -pr]                - [-p]"
    echo "'evaldir, ed'     - Evalulate '_Directory'    - [-ct, -cts, -t, -fs, -fl]     - [-p, -o, -d, -re]"
    echo "'log, l'          - Manage Log Files          - [-c]                          - []"
    echo "'help, h'         - Open MAN Page             - []                            - []"
    echo "'exit, e'         - Exit Script               - []                            - []"
    return 0 # Returns 0 for process compelted
}

# Function to control the exit command
exit_controller() {
    # Exit with code 0 - Process completed
    log "$LOG_INFO" "Script exited with code 0"
    echo "Script Exiting... (0)"
    exit 0
}

#? Main Menu Loop (UI)

# Function to handle the user interface if it's called
user_interface_controller() {
    log "$LOG_INFO" "Main Menu launched"
    # Asking the user to enter their name
    read -p "Enter your name to login: " -a args
    log "$LOG_INFO" "${args[@]} has logged in"
    # Output main menu
    echo "Utility Script:";
    echo "Command, Alt      - Description               - Required Arg(s)               - Optional Args";
    echo "'uuid, id'        - Generate a UUID           - [-ch, -t, -pr]                - [-p]"
    echo "'evaldir, ed'     - Evalulate '_Directory'    - [-ct, -cts, -t, -fs, -fl]     - [-p, -o, -d, -re]"
    echo "'log, l'          - Manage Log Files          - [-c]                          - []"
    echo "'help, h'         - Open MAN Page             - []                            - []"
    echo "'exit, e'         - Exit Script               - []                            - []"
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
}

#? Script Start & Login

# Loggin start of script
log "$LOG_INFO" "Script Started"

# Output main PID
log "$LOG_INFO" "Main Process Run:" $$

# Logging the machine and user using the script
log "$LOG_INFO" "Listing machine user details \n$(w -s)"
log "$LOG_INFO" "Command executed: '${args[@]}'"

# Check the first argument provided and execute the corrosponding command
case $1 in 
    "uuid" | "id")
        uuid_controller &
        log "$LOG_INFO" "Process Run:" $!
        wait
        if [ $? -eq 1 ]; then
            log "$LOG_ERROR" "Something went wrong"
            log "$LOG_ERROR" "Script exited with code 1"
            echo "Script Exiting... (1)"
            exit 1
        fi
        ;;
    "evaldir" | "ed")
        evaldir_controller &
        log "$LOG_INFO" "Process Run:" $!
        wait
        if [ $? -eq 1 ]; then
            log "$LOG_ERROR" "Something went wrong"
            log "$LOG_ERROR" "Script exited with code 1"
            echo "Script Exiting... (1)"
            exit 1
        fi
        ;;
    "log" | "l")
        log_controller &
        log "$LOG_INFO" "Process Run:" $!
        wait
        if [ $? -eq 1 ]; then
            log "$LOG_ERROR" "Something went wrong"
            log "$LOG_ERROR" "Script exited with code 1"
            echo "Script Exiting... (1)"
            exit 1
        fi
        ;;
    "help" | "h")
        help_controller &
        log "$LOG_INFO" "Process Run:" $!
        wait
        if [ $? -eq 1 ]; then
            log "$LOG_ERROR" "Something went wrong"
            log "$LOG_ERROR" "Script exited with code 1"
            echo "Script Exiting... (1)"
            exit 1
        fi
        ;;
    "menu" | "m")
        user_interface_controller &
        log "$LOG_INFO" "Process Run:" $!
        wait
        if [ $? -eq 1 ]; then
            log "$LOG_ERROR" "Something went wrong"
            log "$LOG_ERROR" "Script exited with code 1"
            echo "Script Exiting... (1)"
            exit 1
        fi
        ;;
    *)
        error 1 # Command does not exist
        log "$LOG_ERROR" "Script exited with code 1"
        echo "Script Exiting... (1)"
        exit 1
        ;;
esac

log "$LOG_INFO" "Script exited with code 0"
exit 0 # Script completed successfully