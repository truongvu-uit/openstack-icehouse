#!/bin/bash -ex
#
source general_setup.cfg

echo "############ Cai dat NTP va cau hinh can thiet ############ "
apt-get install ntp -y

echo "############ Sao luu cau hinh cua NTP ############ "
cp /etc/ntp.conf /etc/ntp.conf.bka
rm /etc/ntp.conf
cat /etc/ntp.conf.bka | grep -v ^# | grep -v ^$ >> /etc/ntp.conf

sed -i 's/server/#server/' /etc/ntp.conf
echo "server controller" >> /etc/ntp.conf

echo "############ Cai dat LVM ###################"
apt-get install lvm2 -y

echo "############ Tao LVM vat ly #################"
pvcreate /dev/sdb
vgcreate cinder-volumes /dev/sdb


echo "############ Cai dat volume ###############"
apt-get install cinder-volume -y

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
auth_strategy = keystone
state_path = /var/lib/cinder
lock_path = /var/lock/cinder
volumes_dir = /var/lib/cinder/volumes

glance_host = controller

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

echo "########## Khoi dong lai cinder volume ##############"
service cinder-volume restart
sleep 3
service tgt restart
sleep 3

echo "=====> Da cai xong phan nay"
































