#!/bin/bash

while true; do
    # Promped the user to select a utility
    echo "Bash Utility Script";
    echo "Select a utility:";
    echo "1 - Generate a UUID";
    echo "2 - Do something else (place holder)";
    read -p ": " -a args

    # Check that the correct number of arguments has been provided 
    if [ ${#args[@]} -ne 2 ]; then
        echo "Invalid Args. See the MAN page for help."
        continue
    fi

    # Check the first argument provided
    case ${args[0]} in 
        "uuid")
            # Check the second args for UUID generation
            case ${args[1]} in
                "-v1")
                    uuid=$(uuidgen -t)
                    echo "Generated UUID (version 1): $uuid"
                    break
                    ;;
                "-v4")
                    uuid=$(uuidgen)
                    echo "Generated UUID (version 4): $uuid"
                    break
                    ;;
                *)
                    echo "Invalid UUID Version. See the MAN page for help"
                    ;;
            esac
            ;;
        "e")
            case ${args[1]} in
                "-e")
                    exit 1
                    ;;
            esac
            ;;
        "man")
            exit 1
            man uuid
            ;;
        *)
            echo "Invalid Action. See the MAN page for help."
            ;;
    esac
done

exit 0