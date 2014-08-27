#!/bin/bash

echo ">>>> Configuring Swap space"
fallocate -l 1G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
echo "/swapfile   none    swap    sw    0   0" >> /etc/fstab
sysctl vm.swappiness=10 > /dev/null
echo "vm.swappiness=10" >> /etc/sysctl.conf
sysctl vm.vfs_cache_pressure=50 > /dev/null
echo "vm.vfs_cache_pressure = 50" >> /etc/sysctl.conf

echo ">>>> Adding required repos"
apt-get install -y --force-yes -qq software-properties-common > /dev/null
apt-add-repository -y ppa:ondrej/php5 > /dev/null

echo ">>>> Updating the system"
apt-get -qq update > /dev/null
apt-get -qq upgrade > /dev/null

echo ">>>> Installing base software"
apt-get install -y --force-yes -qq build-essential curl dos2unix gcc git libmcrypt4 libpcre3-dev make unattended-upgrades whois vim > /dev/null

echo ">>>> Setting Timezone (UTC)"
ln -sf /usr/share/zoneinfo/UTC /etc/localtime

echo ">>>> Installing PHP5"
apt-get install -y --force-yes -qq php5-cli php5-dev php-pear php5-mysqlnd php5-sqlite php5-apcu php5-json php5-curl php5-gd php5-gmp php5-imap php5-mcrypt php5-xdebug > /dev/null
php5enmod mcrypt
pecl install mailparse > /dev/null
echo "extension=mailparse.so" > /etc/php5/mods-available/mailparse.ini
ln -sf /etc/php5/mods-available/mailparse.ini /etc/php5/cli/conf.d/20-mailparse.ini

echo ">>>> Installing Composer"
curl -sS https://getcomposer.org/installer | php > /dev/null
mv composer.phar /usr/local/bin/composer
printf "\nPATH=\"/home/vagrant/.composer/vendor/bin:\$PATH\"\n" | tee -a /home/vagrant/.profile

echo ">>>> Configuring PHP5"
sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php5/cli/php.ini
sed -i "s/display_errors = .*/display_errors = On/" /etc/php5/cli/php.ini
sed -i "s/memory_limit = .*/memory_limit = 512M/" /etc/php5/cli/php.ini
sed -i "s/;date.timezone.*/date.timezone = UTC/" /etc/php5/cli/php.ini

echo ">>>> Installing Apache2"
apt-get install -y --force-yes -qq apache2 > /dev/null
apt-get install -y --force-yes -qq libapache2-mod-php5 > /dev/null
echo "ServerName localhost" > /etc/apache2/conf-available/fqdn.conf
a2enconf fqdn > /dev/null
a2enmod rewrite > /dev/null

echo ">>>> Configuring Apache2"
sed -i "s/export APACHE_RUN_USER=www-data/export APACHE_RUN_USER=vagrant/" /etc/apache2/envvars
rm /etc/apache2/sites-available/000-default.conf
rm /etc/apache2/sites-enabled/000-default.conf
rm /etc/apache2/sites-available/default-ssl.conf
service apache2 restart > /dev/null

echo ">>>> Adding vagrant user to group www-data"
usermod -a -G www-data vagrant

echo ">>>> Installing sqlite3"
apt-get install -y --force-yes sqlite3 libsqlite3-dev > /dev/null

echo ">>>> Installing MySQL"
debconf-set-selections <<< "mysql-server mysql-server/root_password password secret"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password secret"
apt-get install -y --force-yes -qq mysql-server > /dev/null

echo ">>>> Configuring MySQL"
sed -i '/^bind-address/s/bind-address.*=.*/bind-address = 10.0.2.15/' /etc/mysql/my.cnf
mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO root@'10.0.2.2' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
service mysql restart > /dev/null

echo ">>>> Creating lindellocal MySQL user"
mysql --user="root" --password="secret" -e "CREATE USER 'lindellocal'@'10.0.2.2' IDENTIFIED BY 'secret';"
mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO 'lindellocal'@'10.0.2.2' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
mysql --user="root" --password="secret" -e "GRANT ALL ON *.* TO 'lindellocal'@'%' IDENTIFIED BY 'secret' WITH GRANT OPTION;"
mysql --user="root" --password="secret" -e "FLUSH PRIVILEGES;"
mysql --user="root" --password="secret" -e "CREATE DATABASE lindellocal;"
service mysql restart > /dev/null

echo ">>>> Copying bash aliases"
cp /vagrant/aliases /home/vagrant/.bash_aliases

echo ">>>> Cleaning Up"
apt-get -qq clean > /dev/null
apt-get -qq autoclean > /dev/null
apt-get -qq autoremove > /dev/null

echo ">>>> Updating composer"
/usr/local/bin/composer self-update > /dev/null
