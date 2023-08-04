#!/bin/bash

# Get the full path of the script
script_path="$0"

# Extract the directory path from the script path
script_directory=$(dirname "$script_path")

current_cli_machine="$1"

remote_cron_dir='/home/ecs-user/.local/etc/cron.d'

mkdir -p $remote_cron_dir

local_cron_dir="$script_directory/$current_cli_machine/crontab"

# replace the content of supervisor/conf.d
if [ -d "$local_cron_dir" ]; then

    # delete all contab configs matching the naming pattern
    for config_file in "$remote_cron_dir"/php_partying*.crontab; do
        if [ -f "$config_file" ]; then
            echo "deleting: $config_file"
            rm "$config_file"
        fi
    done

    # move the content of the source folder to the destination folder
    mv "$local_cron_dir"/* "$remote_cron_dir"

    if [ $? -eq 0 ]; then
        echo "New cron tabs from: $local_cron_dir"
        cat "$remote_cron_dir"/*.crontab | crontab -
    else
        echo "Error: updating crontabs failed."
        exit 1
    fi
fi
