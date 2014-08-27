#!/usr/bin/env bash

block="<VirtualHost *:80>
    ServerName $1

    ServerAdmin webmaster@$1
    DocumentRoot $2

    <Directory $2/>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$1_error.log
    CustomLog \${APACHE_LOG_DIR}/$1_access.log combined
</VirtualHost>
"

echo "$block" > "/etc/apache2/sites-available/$1.conf"
ln -fs "/etc/apache2/sites-available/$1.conf" "/etc/apache2/sites-enabled/$1.conf"
service apache2 restart > /dev/null
