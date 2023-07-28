#!/bin/bash

# Get the full path of the script
script_path="$0"

# Extract the directory path from the script path
script_directory=$(dirname "$script_path")

task_file_name="$1.conf"

# loop through config files to locate where the task is
configs_dir="$script_directory/supervisor"

target_cmd=""

function process_files_recursively() {
    local current_dir="$1"

    for file in "$current_dir"/*; do
        if [ -f "$file" ]; then
            file_name=$(basename "$file")

            target_file

            if [[ "$file_name" == "$task_file_name" ]]; then
                dir_name=$(dirname "$file")
                target_cmd=$(basename "$dir_name")
                echo "Processing matching file: $file_name, target: $target_cmd"
            fi
        elif [ -d "$file" ]; then
            process_files_recursively "$file"
        fi
    done
}

process_files_recursively "$configs_dir"
