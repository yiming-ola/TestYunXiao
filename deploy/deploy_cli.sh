#!/bin/bash

# Get the full path of the script
script_path="$0"

# Extract the directory path from the script path
script_directory=$(dirname "$script_path")

# Get the parent directory of the script's directory, should be something like /etc/ecs-user/webroot_new_builds/${TIMESTAMP}
build_directory=$(dirname "$script_directory")

# replace the running supervisor conf.d with the mapped folder. folder name will be given from CI.
current_cli_machine="$1"

# tasks are separated by comma (,)
task_names="$2"

echo "current cli machine:$current_cli_machine, tasks to restart:$task_names"

remote_supervisor_conf_d="/home/ecs-user/.local/etc/supervisor/conf.d"

local_supervisor_conf_d="$script_directory/$current_cli_machine/supervisor"

if [ -d "$local_supervisor_conf_d" ]; then

    # delete all supervisor configs matching the naming pattern
    for config_file in "$remote_supervisor_conf_d"/php_partying*.conf; do
        if [ -f "$config_file" ]; then
            echo "deleting: $config_file"
            rm "$config_file"
        fi
    done

    # Move the content of the source folder to the destination folder
    mv "$local_supervisor_conf_d"/* "$remote_supervisor_conf_d"

    if [ $? -eq 0 ]; then
        echo "New supervisor configs from: $local_supervisor_conf_d"
        sudo supervisorctl reread
        sudo supervisorctl update
    else
        echo "Error: updating supervisor configs failed."
        exit 1
    fi
fi

# handle restarting tasks

# split the tasks into an array
read -ra task_arr <<< "$task_names"

# loop through the array
for task_name in "${task_arr[@]}"; do
    if [ -n "$task_name" ]; then
        echo "now handling: $task_name"
        # get the targeted machine name from out put file of targeting.sh
        targeted_cli_machine=$(bash "$script_directory/targeting.sh" "$task_name")
        echo "Found $task_name running on: $targeted_cli_machine"

        read -ra cli_arr <<< "$targeted_cli_machine"

        for cli_machine in "${cli_arr[@]}"; do
            # given a task name, if it belongs to the current folder($folder_name), restart it
            if [ -n "$cli_machine" ] && [ "$current_cli_machine" = "$cli_machine" ]; then
                echo "Restarting $task_name of $current_cli_machine..."
                sudo supervisorctl restart $task_name
            fi
        done
    fi
done
