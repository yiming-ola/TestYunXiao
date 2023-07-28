#!/bin/bash

# Get the full path of the script
script_path="$0"

# Extract the directory path from the script path
script_directory=$(dirname "$script_path")

# Get the parent directory of the script's directory, should be something like /etc/ecs-user/webroot_new_builds/${TIMESTAMP}
build_directory=$(dirname "$script_directory")

# read ip

# map ip to correct cmd folder.

# replace the running supervisor conf.d with the cmd folder.

# reread, if has any changes, do update.

# tell any file changes(this newly unzipped archive vs running archive), if have, reload the task accordingly

# given a task name, if it belongs to the cmd folder, restart it
