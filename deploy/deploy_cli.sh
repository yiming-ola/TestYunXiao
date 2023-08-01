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

# replace the content of supervisor/conf.d
rsync -av --delete $local_supervisor_conf_d/ $remote_supervisor_conf_d

if [ $? -eq 0 ]; then
    echo "New supervisor configs from: $local_supervisor_conf_d"
    sudo supervisorctl reread
    sudo supervisorctl update
else
    echo "Error: updating supervisor configs failed."
    exit 1
fi

# handle restarting tasks

# save the current IFS value
OLDIFS=$IFS

# Set IFS to comma (,) as the delimiter
IFS=','

# split the tasks into an array
read -ra task_arr <<< "$task_names"

# restore IFS to its original value
IFS=$OLDIFS

# loop through the array
for task_name in "${task_arr[@]}"; do
    if [ -n "$task_name" ]; then
        echo "now handling: $task_name"
        # get the targeted machine name from out put file of targeting.sh
        targeted_cli_machine=$(bash "$script_directory/targeting.sh" "$task_name")
        echo "Found $task_name running on: $targeted_cli_machine"
        # given a task name, if it belongs to the current folder($folder_name), restart it
        if [ -n "$targeted_cli_machine" ] && [ "$current_cli_machine" = "$targeted_cli_machine" ]; then
            echo "Restarting $task_name of $current_cli_machine..."
            sudo supervisorctl restart $task_name
        fi
    fi
done
