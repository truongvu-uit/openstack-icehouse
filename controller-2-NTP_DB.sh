#!/bin/bash -ex
#
source general_setup.cfg

echo "=====> Cai dat NTP va cau hinh NTP"
sleep 3 
apt-get install ntp -y

rm /var/lib/ntp/ntp.conf.dhcp
rm -f /var/lib/ntp/ntp.conf.dhcp
service ntp restart
ntpq -c peers
ntpq -c assoc

echo "=====> Cai dat RABBITMQ  va cau hinh RABBITMQ"
sleep 3
apt-get install rabbitmq-server -y
rabbitmqctl change_password guest RABBIT_PASS
sleep 3

service rabbitmq-server restart
echo "=====> Da cai xong NTP "

#####################################################

echo "##### Cai dat MYSQL #####"
sleep 3

echo mysql-server mysql-server/root_password password $MYSQL_PASS | debconf-set-selections
echo mysql-server mysql-server/root_password_again password $MYSQL_PASS | debconf-set-selections
#apt-get update
apt-get install mysql-server python-mysqldb curl expect -y

echo "##### Cau hinh cho MYSQL #####"
sleep 3

sed -i 's/127.0.0.1/controller/g' /etc/mysql/my.cnf
sed -i "/bind-address/a\default-storage-engine = innodb\n\
innodb_file_per_table\n\
collation-server = utf8_general_ci\n\
init-connect = 'SET NAMES utf8'\n\
character-set-server = utf8" /etc/mysql/my.cnf
#
service mysql restart
mysql_install_db

SECURE_MYSQL=$(expect -c "
set timeout 5
spawn mysql_secure_installation
expect \"Enter current password for root (enter for none):\"
send \"$MYSQL_PASS\r\"
expect \"Change the root password?\"
send \"n\r\"
expect \"Remove anonymous users?\"
send \"y\r\"
expect \"Disallow root login remotely?\"
send \"y\r\"
expect \"Remove test database and access to it?\"
send \"y\r\"
expect \"Reload privilege tables now?\"
send \"y\r\"
expect eof
")
echo "$SECURE_MYSQL"
apt-get remove --purge -y expect
echo "=====> Da cai xong phan nay"
