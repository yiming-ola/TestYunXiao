#!/bin/bash

# switch user to ecs-user

# refer to https://medium.com/hackernoon/truly-atomic-deployments-with-nginx-and-php-fpm-aed8a8ac1cd9
fastcgi_param='fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;'

nginx_fastcgi_param_path='/etc/nginx/fastcgi_params'
local_setting='/home/webroot/origin/deploy/nginx_settings.conf'
remote_setting='/etc/nginx/sites-available/default'
enabled_setting='/etc/nginx/sites-enabled/'
back_up_dir='/etc/nginx/sites-available/back_up'

# only insert when the param does not exist
if [ ! -e $remote_setting ]; then
    touch $remote_setting
fi

# link settings
sudo ln -s $remote_setting $enabled_setting

if ! grep -qF "$fastcgi_param" $nginx_fastcgi_param_path; then
    echo "Inserting fastcgi_param..."
    sudo sed -i "1i\\$fastcgi_param" $nginx_fastcgi_param_path
else
    echo "Fastcgi_param ok."
fi

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
    sudo cp $remote_setting $back_up_file

    # replace nginx config
    sudo cat $local_setting > $remote_setting

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
        sudo cp $back_up_file $remote_setting
        sudo rm -rf $back_up_file
    fi
fi

# deleting back up files older than 14 days.
find $back_up_dir -type f -mtime +14 -exec rm {} \;
