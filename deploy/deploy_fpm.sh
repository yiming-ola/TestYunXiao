#!/bin/bash

# Get the full path of the script
script_path="$0"

# Extract the directory path from the script path
script_directory=$(dirname "$script_path")

# Get the parent directory of the script's directory, should be something like /etc/ecs-user/webroot_new_builds/${TIMESTAMP}
build_directory=$(dirname "$script_directory")
builds_repo=$(dirname "$build_directory")

local_setting="$script_directory/nginx/nginx_settings.conf"
sites_available='/home/ecs-user/.local/etc/nginx/sites-available'
enabled_setting='/home/ecs-user/.local/etc/nginx/sites-enabled/'
remote_setting="$sites_available/default"
back_up_dir="$sites_available/back_up"

fixed_build="$builds_repo/php_partying"

if [ ! -e $remote_setting ]; then
    mkdir -p $sites_available
    echo "# new empty settings." > $remote_setting
    # link settings
    ln -s $remote_setting $enabled_setting
fi

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
    sudo nginx -t
    if [ $? -eq 0 ]; then
        echo "Nginx configuration test passed successfully. Updating and reloading Nginx..."
        # reload nginx
        sudo nginx -s reload
        echo "Done updating local config. Back up file of the older config: $back_up_name"
    else
        echo "Nginx configuration test failed!!!! restore changes to the config."

        # restore config file
        cp "$back_up_file" "$remote_setting"
        rm -rf "$back_up_file"
    fi
fi

# deleting back up files older than 3 days. sudo prefix is needed to use find command.
sudo find $back_up_dir -type f -mtime +3 -exec rm {} \;

# link the new build to application path

webroot_path='/home/ecs-user/webroot/php_partying'

current_target=''

# important: cli tasks resolve symlink and use the resolved absolute path.
# in this case, the real name of the build should be fixed, otherwise cli task fails to locate resources.
if [ -e "$webroot_path" ]; then
    current_target=$(readlink -f "$webroot_path")
    echo "Symlink to the build: $current_target"

    # duplicate a copy
    copy="$builds_repo/php_partying_copy/"
    rsync -av "$build_directory/" "$builds_repo/php_partying_copy/"

    # Update the symlink to the newly unzipped build
    ln -snf "$build_directory" "$webroot_path"
    echo "Update the symlink to the newly unzipped build : $build_directory"

    # delete the old build
    if [ -n "$current_target" ] && [ -d $current_target ]; then
        rm -r "$current_target"
    fi

    # rename the copy to $fixed_build
    mv "$copy" "$fixed_build"

    # Symlink back to $fixed_build
    ln -snf "$fixed_build" "$webroot_path"
    echo "Fixed build updated."

    # Delete the newly unzipped build
    rm -r "$build_directory"
    echo "$build_directory deleted."

else
    # Rename the newly unzipped build to $fixed_build
    mv "$build_directory" "$fixed_build"

    # Symlink to webroot
    if ln -snf "$fixed_build" "$webroot_path"; then
        echo "New build: $fixed_build, Symlink updated successfully."
        sudo systemctl reload php7.2-fpm
        exit 0
    else
        echo "Error: Symlink update failed."
        exit 1
    fi
fi
