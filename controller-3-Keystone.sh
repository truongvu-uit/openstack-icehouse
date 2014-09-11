#!/bin/bash -ex
#
source general_setup.cfg

echo "##### Cai dat keystone #####"
apt-get install keystone -y

filekeystone=/etc/keystone/keystone.conf
test -f $filekeystone.orig || cp $filekeystone $filekeystone.orig
#Chen noi dung file /etc/keystone/keystone.conf
cat << EOF > $filekeystone
[DEFAULT]
admin_token=ADMIN_TOKEN
log_dir=/var/log/keystone
[assignment]
[auth]
[cache]
[catalog]
[credential]
[database]
connection=mysql://keystone:KEYSTONE_DBPASS@controller/keystone
[ec2]
[endpoint_filter]
[federation]
[identity]
[kvs]
[ldap]
[matchmaker_ring]
[memcache]
[oauth1]
[os_inherit]
[paste_deploy]
[policy]
[revoke]
[signing]
[ssl]
[stats]
[token]
[trust]
[extra_headers]
Distribution=Ubuntu
EOF
#
echo "##### Xoa DB mac dinh #####"
rm /var/lib/keystone/keystone.db
echo "=====> Tao db"
cat <<EOF | mysql -u root -p$MYSQL_PASS
CREATE DATABASE keystone;
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'localhost' IDENTIFIED BY 'KEYSTONE_DBPASS';
GRANT ALL PRIVILEGES ON keystone.* TO 'keystone'@'%' IDENTIFIED BY 'KEYSTONE_DBPASS';
EOF

echo "##### Dong bo cac bang trong DB #####"
sleep 3
su -s /bin/sh -c "keystone-manage db_sync" keystone
sleep 20
echo "##### Khoi dong lai MYSQL #####"
service keystone restart
echo "=====> Da cai xong keystone"

#############################################################
echo "=====> Define users, tenants, and roles"
sleep 3
export OS_SERVICE_TOKEN=ADMIN_TOKEN
export OS_SERVICE_ENDPOINT=http://controller:35357/v2.0
sleep 10
#Create an administrative user
keystone user-create --name=admin --pass=ADMIN_PASS --email=admin@controller.com

keystone role-create --name=admin
keystone tenant-create --name=admin --description="Admin Tenant"
keystone user-role-add --user=admin --tenant=admin --role=admin
keystone user-role-add --user=admin --role=_member_ --tenant=admin

#Create a normal user
keystone user-create --name=demo --pass=DEMO_PASS --email=demo@controller.com
keystone tenant-create --name=demo --description="Demo Tenant"
keystone user-role-add --user=demo --role=_member_ --tenant=demo

#Create a service tenant
keystone tenant-create --name=service --description="Service Tenant"
#Define services and API endpoints
keystone service-create --name=keystone --type=identity --description="OpenStack Identity"
echo "dang tao"
keystone endpoint-create --service-id=$(keystone service-list | awk '/ identity / {print $2}') --publicurl=http://controller:5000/v2.0 --internalurl=http://controller:5000/v2.0 --adminurl=http://controller:35357/v2.0

echo "da tao xong==============="
sleep 10

#Verify the Identity Service installation
unset OS_SERVICE_TOKEN OS_SERVICE_ENDPOINT
keystone --os-username=admin --os-password=ADMIN_PASS --os-auth-url=http://controller:35357/v2.0 token-get
keystone --os-username=admin --os-password=ADMIN_PASS --os-tenant-name=admin --os-auth-url=http://controller:35357/v2.0 token-get

echo "########## TAO FILE CHO BIEN MOI TRUONG ##########"
echo "export OS_USERNAME=admin" > admin-openrc.sh
echo "export OS_PASSWORD=ADMIN_PASS" >> admin-openrc.sh
echo "export OS_TENANT_NAME=admin" >> admin-openrc.sh
echo "export OS_AUTH_URL=http://controller:35357/v2.0" >> admin-openrc.sh
chmod +x admin-openrc.sh

echo "########## Thuc thi bien moi truong ##########"
# source admin-openrc.sh
cat admin-openrc.sh >> /etc/profile
cp admin-openrc.sh /root/admin-openrc.sh

source admin-openrc.sh
keystone token-get
keystone user-list
keystone user-role-list --user admin --tenant admin


















