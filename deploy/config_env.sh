#!/bin/bash

# refer to https://medium.com/hackernoon/truly-atomic-deployments-with-nginx-and-php-fpm-aed8a8ac1cd9
fastcgi_param='fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;'
nginx_fastcgi_param_path='/etc/nginx/fastcgi_params'
local_setting='/home/webroot/origin/deploy/nginx_settings.conf'
remote_setting='/etc/nginx/sites-available/default'

# only insert when the param does not exist
if ![ -e $remote_setting ]; then
    touch $remote_setting
fi

if ! grep -qF $fastcgi_param $nginx_fastcgi_param_path; then
    echo "Inserting fastcgi_param..."
    sudo sed -i "1i\\$fastcgi_param" $nginx_fastcgi_param_path
else
    echo "fastcgi_param ok."
fi

# aligning the local nginx conifg to nginx_settings.conf
if cmp -s $local_setting $remote_setting; then
    echo "No difference found between nginx_settings.conf and sites-available default settings, skip rewritting local config."
else
    echo "The content of nginx_settings.conf and sites-available default setting is different. Updating local config..."
    # back up config
    current_date=$(date '+%Y-%m-%d-%H-%M-%S')
    back_up_name="default_$current_date.backup"
    sudo cp $remote_setting /etc/nginx/sites-available/$back_up_name
    sudo cat $local_setting > $remote_setting

    echo "Done updating local config. Back up file of the older config: $back_up_name"
fi
