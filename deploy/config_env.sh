#!/bin/bash

# switch user to ecs-user

# Get the full path of the script
script_path="$0"

# Extract the directory path from the script path
script_directory=$(dirname "$script_path")

# Get the parent directory of the script's directory, should be something like /etc/ecs-user/webroot_new_builds/${TIMESTAMP}
build_directory=$(dirname "$script_directory")

local_setting="$script_directory/nginx_settings.conf"
remote_setting='/home/ecs-user/.local/etc/nginx/sites-available/default'
enabled_setting='/home/ecs-user/.local/etc/nginx/sites-enabled/'
back_up_dir='/home/ecs-user/.local/etc/nginx/sites-available/back_up'

if [ ! -e $remote_setting ]; then
    touch $remote_setting
fi

# link settings
ln -s $remote_setting $enabled_setting

# Enable errexit option
set -e

# aligning the local nginx conifg to nginx_settings.conf
if cmp -s $local_setting $remote_setting; then
    echo "No difference found between nginx_settings.conf and sites-available default settings, skip rewritting local config."
else
    echo "The content of nginx_settings.conf and sites-available default setting is different. Updating local config..."

    current_date=$(date '+%Y-%m-%d-%H-%M-%S')
    back_up_name="default_$current_date.backup"

    mkdir -p $back_up_dir
    back_up_file="$back_up_dir/$back_up_name"

    # back up config
    cp $remote_setting $back_up_file

    # replace nginx config
    cat $local_setting > $remote_setting

    # check config file
    nginx -t
    if [ $? -eq 0 ]; then
        echo "Nginx configuration test passed successfully. Updating and reloading Nginx..."
        # reload nginx
        nginx -s reload
        echo "Done updating local config. Back up file of the older config: $back_up_name"
    else
        echo "Nginx configuration test failed!!!! restore changes to the config."

        # restore config file
        cp $back_up_file $remote_setting
        rm -rf $back_up_file
    fi
fi

# deleting back up files older than 14 days.
find $back_up_dir -type f -mtime +14 -exec rm {} \;

# link the new build to application path

new_root_dir="$build_directory/tutorial/public"

service_folder='/home/ecs-user/webroot/ym_try_try'

ln -sf $new_root_dir $service_folder

echo "Linked $new_root_dir to $service_folder"

# delete other builds
builds_dir=$(dirname "$build_directory")
# find $builds_dir -type d ! -name "$build_directory" -exec rm -r {} \;
find $builds_dir -type d ! -name "$build_directory" -print;
