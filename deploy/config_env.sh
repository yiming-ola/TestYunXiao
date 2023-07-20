#!/bin/bash

# refer to https://medium.com/hackernoon/truly-atomic-deployments-with-nginx-and-php-fpm-aed8a8ac1cd9
fastcgi_param='fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;'
nginx_fastcgi_param_path='/etc/nginx/fastcgi_params'
local_setting='/home/webroot/origin/deploy/nginx_settings.conf'
remote_setting='/etc/nginx/sites-available/default'
back_up_dir="/etc/nginx/sites-available/back_up"
# only insert when the param does not exist
if [ ! -e $remote_setting ]; then
    touch $remote_setting
fi

sudo ln -s $remote_setting /etc/nginx/sites-enabled/

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

    # check config file
    sudo nginx -t -c $remote_setting
    if [ $? -eq 0 ]; then
        echo "Nginx configuration test passed successfully. Updating and reloading Nginx..."
        # back up config
        sudo cp $remote_setting "$back_up_dir/$back_up_name"
        # replace nginx config
        sudo cat $local_setting > $remote_setting
        # reload nginx
        sudo nginx -s reload
        echo "Done updating local config. Back up file of the older config: $back_up_name"
    else
        echo "Nginx configuration test failed!!!!"
    fi
fi

# deleting back up files older than 14 days.
find $back_up_dir -type f -mtime +14 -exec rm {} \;
