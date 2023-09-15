#!/bin/bash

# Get the full path of the script
script_path="$0"

# Extract the directory path from the script path
script_directory=$(dirname "$script_path")

local_setting="$script_directory/nginx/ngx_settings_request_filter.conf"
sites_available='/home/ecs-user/.local/etc/nginx/sites-available'
enabled_setting='/home/ecs-user/.local/etc/nginx/sites-enabled/'
remote_setting="$sites_available/default"

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
        exit 1
    fi
fi
