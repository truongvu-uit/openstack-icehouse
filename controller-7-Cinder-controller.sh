#!/bin/bash -ex
#
source general_setup.cfg

echo "########## Cai dat cac goi cho CINDER ##########"
apt-get install cinder-api cinder-scheduler -y

echo "########## Cau hinh file cho cinder.conf ##########"
filecinder=/etc/cinder/cinder.conf
test -f $filecinder.orig || cp $filecinder $filecinder.orig
rm $filecinder
cat << EOF > $filecinder
[DEFAULT]
rootwrap_config = /etc/cinder/rootwrap.conf
api_paste_confg = /etc/cinder/api-paste.ini
iscsi_helper = tgtadm
volume_name_template = volume-%s
volume_group = cinder-volumes
verbose = True
state_path = /var/lib/cinder
lock_path = /var/lock/cinder
volumes_dir = /var/lib/cinder/volumes

rpc_backend = cinder.openstack.common.rpc.impl_kombu
rabbit_host = controller
rabbit_port = 5672
rabbit_userid = guest
rabbit_password = RABBIT_PASS

[database]
connection = mysql://cinder:CINDER_DBPASS@controller/cinder

[keystone_authtoken]
auth_uri = http://controller:5000
auth_host = controller
auth_port = 35357
auth_protocol = http
admin_tenant_name = service
admin_user = cinder
admin_password = CINDER_PASS
EOF

echo "=====> Tao db"
cat <<EOF | mysql -u root -p$MYSQL_PASS
CREATE DATABASE cinder;
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'localhost' IDENTIFIED BY 'CINDER_DBPASS';
GRANT ALL PRIVILEGES ON cinder.* TO 'cinder'@'%' IDENTIFIED BY 'CINDER_DBPASS';
EOF

chown cinder:cinder $filecinder

echo "########## Dong bo cho cinder ##########"
sleep 3
su -s /bin/sh -c "cinder-manage db sync" cinder
sleep 10

echo "########## Create a cinder use ##########"
source admin-openrc.sh
keystone user-create --name=cinder --pass=CINDER_PASS --email=cinder@example.com
keystone user-role-add --user=cinder --tenant=service --role=admin
keystone service-create --name=cinder --type=volume --description="OpenStack Block Storage"
keystone endpoint-create --service-id=$(keystone service-list | awk '/ volume / {print $2}') --publicurl=http://controller:8776/v1/%\(tenant_id\)s --internalurl=http://controller:8776/v1/%\(tenant_id\)s --adminurl=http://controller:8776/v1/%\(tenant_id\)s
sleep 5
keystone service-create --name=cinderv2 --type=volumev2 --description="OpenStack Block Storage v2"
keystone endpoint-create --service-id=$(keystone service-list | awk '/ volumev2 / {print $2}') --publicurl=http://controller:8776/v2/%\(tenant_id\)s --internalurl=http://controller:8776/v2/%\(tenant_id\)s --adminurl=http://controller:8776/v2/%\(tenant_id\)s
sleep 5

echo "########## Khoi dong lai CINDER ##########"
service cinder-scheduler restart
service cinder-api restart
echo "=====> Da hoan thanh phan nay"

