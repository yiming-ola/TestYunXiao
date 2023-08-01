#!/bin/bash

# Get the full path of the script
script_path="$0"

# Extract the directory path from the script path
script_directory=$(dirname "$script_path")

current_cli_machine="$1"

remote_cron_dir='/home/ecs-user/.local/etc/cron.d'

local_cron_dir="$script_directory/$current_cli_machine/crontab"

# replace the content of supervisor/conf.d
rsync -av --delete $local_cron_dir/ $remote_cron_dir

cat "$remote_cron_dir/*.crontab" | crontab -
