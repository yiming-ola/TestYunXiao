#!/bin/bash

# Get the full path of the script
script_path="$0"

# Extract the directory path from the script path
script_directory=$(dirname "$script_path")

task_name="$1"

# loop through config files to locate where the task is
configs_dir="$script_directory/supervisor"

function process_files_recursively() {
    local current_dir="$1"

    for file in "$current_dir"/*; do
        if [ -f "$file" ]; then
            # Perform your desired actions with the file here
            echo "Processing file: $file"
            # Add more commands as needed, for example:
            # do_something_with_file "$file"
        elif [ -d "$file" ]; then
            # If the item is a subdirectory, call the function recursively
            process_files_recursively "$file"
        fi
    done
}

process_files_recursively "$configs_dir"
