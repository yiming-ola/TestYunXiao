#!/bin/bash

# Get the full path of the script
script_path="$0"

# Extract the directory path from the script path
script_directory=$(dirname "$script_path")

task_file_name="$1.conf"

target_cli_machine=""

# loop through config files to locate where the task is
for dir in "$script_directory"/*/; do
    # check if the subdirectory contains a folder named "supervisor"
    config_dir="$dir/supervisor"
    if [ -d "$config_dir" ]; then
        for file in "$config_dir"/*; do
        if [ -f "$file" ]; then
            file_name=$(basename "$file")
            if [ "$file_name" == "$task_file_name" ]; then
                target_cli_machine=$(basename "$dir")
                break;
            fi
        fi
    fi
done

echo $target_cli_machine
