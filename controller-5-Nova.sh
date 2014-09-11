#!/bin/bash -ex
#
source general_setup.cfg


echo "########## CAI DAT NOVA TREN CONTROLLER ##########"
apt-get install nova-api nova-cert nova-conductor nova-consoleauth nova-novncproxy nova-scheduler python-novaclient -y

controlnova=/etc/nova/nova.conf
test -f $controlnova.orig || cp $controlnova $controlnova.orig
rm $controlnova
touch $controlnova
cat << EOF >> $controlnova
[DEFAULT]
dhcpbridge_flagfile=/etc/nova/nova.conf
dhcpbridge=/usr/bin/nova-dhcpbridge
logdir=/var/log/nova
state_path=/var/lib/nova
lock_path=/var/lock/nova
force_dhcp_release=True
iscsi_helper=tgtadm
libvirt_use_virtio_for_bridges=True
connection_type=libvirt
root_helper=sudo nova-rootwrap /etc/nova/rootwrap.conf
verbose=True
ec2_private_dns_show_ip=True
api_paste_config=/etc/nova/api-paste.ini
volumes_path=/var/lib/nova/volumes
enabled_apis=ec2,osapi_compute,metadata
auth_strategy = keystone
# Khai bao cho RABBITMQ
rpc_backend = rabbit
rabbit_host = controller
rabbit_password = RABBIT_PASS
# Cau hinh cho VNC
my_ip = $CON_MGNT_IP
vncserver_listen = $CON_MGNT_IP
vncserver_proxyclient_address = $CON_MGNT_IP
# Tu dong Start VM khi reboot OpenStack
resume_guests_state_on_host_boot=True
#Cho phep dat password cho Instance khi khoi tao
libvirt_inject_password = True
libvirt_inject_partition = -1
enable_instance_password = True
network_api_class = nova.network.api.API
neutron_url = http://controller:9696
neutron_auth_strategy = keystone
neutron_admin_tenant_name = service
neutron_admin_username = neutron
neutron_admin_password = NOVA_PASS
neutron_admin_auth_url = http://controller:35357/v2.0
linuxnet_interface_driver = nova.network.linux_net.LinuxOVSInterfaceDriver
firewall_driver = nova.virt.firewall.NoopFirewallDriver
security_group_api = nova
service_neutron_metadata_proxy = true
neutron_metadata_proxy_shared_secret = $METADATA_SECRET
auth_strategy = keystone

[database]
connection=mysql://nova:NOVA_DBPASS@controller/nova

[keystone_authtoken]
auth_uri = http://controller:5000
auth_host = controller
auth_port = 35357
auth_protocol = http
admin_tenant_name = service
admin_user = nova
admin_password = NOVA_PASS
EOF

echo "=====> Tao db"
cat <<EOF | mysql -u root -p$MYSQL_PASS
CREATE DATABASE nova;
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'localhost' IDENTIFIED BY 'NOVA_DBPASS';
GRANT ALL PRIVILEGES ON nova.* TO 'nova'@'%' IDENTIFIED BY 'NOVA_DBPASS';
EOF

echo "########## XOA FILE DB MAC DINH ##########"
rm /var/lib/nova/nova.sqlite
rm -f /var/lib/nova/nova.sqlite

echo "########## DONG BO DB CHO NOVA ##########"
sleep 7
su -s /bin/sh -c "nova-manage db sync" nova 
sleep 10

source admin-openrc.sh

keystone user-create --name=nova --pass=NOVA_PASS --email=nova@example.com
keystone user-role-add --user=nova --tenant=service --role=admin
keystone service-create --name=nova --type=compute --description="OpenStack Compute"
keystone endpoint-create --service-id=$(keystone service-list | awk '/ compute / {print $2}') --publicurl=http://controller:8774/v2/%\(tenant_id\)s --internalurl=http://controller:8774/v2/%\(tenant_id\)s --adminurl=http://controller:8774/v2/%\(tenant_id\)s

service nova-api restart
service nova-cert restart
service nova-consoleauth restart
service nova-scheduler restart
service nova-conductor restart
service nova-novncproxy restart

sleep 5
nova image-list
sleep 15

echo "########## KIEM TRA LAI DICH VU NOVA ##########"
sleep 5
nova-manage service list
sleep 15

echo "=====> Da cai xong phan nay"
