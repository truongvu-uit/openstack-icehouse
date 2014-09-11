#!/bin/bash -ex
#
source general_setup.cfg

SERVICE_ID=`keystone tenant-get service | awk '$2~/^id/{print $4}'`

echo "=====> Tao db"
cat <<EOF | mysql -u root -p$MYSQL_PASS
CREATE DATABASE neutron;
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'localhost' IDENTIFIED BY 'NEUTRON_DBPASS';
GRANT ALL PRIVILEGES ON neutron.* TO 'neutron'@'%' IDENTIFIED BY 'NEUTRON_DBPASS';
EOF

keystone user-create --name neutron --pass NEUTRON_PASS --email neutron@example.com
keystone user-role-add --user neutron --tenant service --role admin
keystone service-create --name neutron --type network --description "OpenStack Networking"
keystone endpoint-create --service-id $(keystone service-list | awk '/ network / {print $2}') --publicurl http://controller:9696 --adminurl http://controller:9696 --internalurl http://controller:9696

echo "########## CAI DAT NEUTRON TREN CONTROLLER################"
apt-get install neutron-server neutron-plugin-ml2 -y

echo "########## SUA FILE CAU HINH NEUTRON CHO CONTROLLER ##########"
controlneutron=/etc/neutron/neutron.conf
test -f $controlneutron.orig || cp $controlneutron $controlneutron.orig
rm $controlneutron
touch $controlneutron
cat << EOF >> $controlneutron
[DEFAULT]
rpc_backend = neutron.openstack.common.rpc.impl_kombu
rabbit_host = controller
rabbit_password = RABBIT_PASS
state_path = /var/lib/neutron
lock_path = \$state_path/lock
core_plugin = neutron.plugins.ml2.plugin.Ml2Plugin
notification_driver = neutron.openstack.common.notifier.rpc_notifier
verbose = True
auth_strategy = keystone
notify_nova_on_port_status_changes = True
notify_nova_on_port_data_changes = True
nova_url = http://controller:8774/v2
nova_admin_username = nova
#Thay ID trong lenh "keystone tenant-get service" vao dong duoi
nova_admin_tenant_id = $SERVICE_ID
nova_admin_password = NOVA_PASS
nova_admin_auth_url = http://controller:35357/v2.0
core_plugin = ml2
service_plugins = router
allow_overlapping_ips = True
[quotas]
[agent]
root_helper = sudo /usr/bin/neutron-rootwrap /etc/neutron/rootwrap.conf
[keystone_authtoken]
auth_uri = http://controller:5000
auth_host = controller
auth_protocol = http
auth_port = 35357
admin_tenant_name = service
admin_user = neutron
admin_password = NEUTRON_PASS
signing_dir = \$state_path/keystone-signing
[database]
connection=mysql://neutron:NEUTRON_DBPASS@controller/neutron
[service_providers]
service_provider=LOADBALANCER:Haproxy:neutron.services.loadbalancer.drivers.haproxy.plugin_driver.HaproxyOnHostPluginDriver:default
service_provider=VPN:openswan:neutron.services.vpn.service_drivers.ipsec.IPsecVPNDriver:default
EOF

echo "########## SUA FILE CAU HINH ML2 CHO CONTROLLER ##########"
controlML2=/etc/neutron/plugins/ml2/ml2_conf.ini
test -f $controlML2.orig || cp $controlML2 $controlML2.orig
rm $controlML2
touch $controlML2
cat << EOF >> $controlML2
[ml2]
type_drivers = gre
tenant_network_types = gre
mechanism_drivers = openvswitch
[ml2_type_flat]
[ml2_type_vlan]
[ml2_type_gre]
tunnel_id_ranges = 1:1000
[ml2_type_vxlan]
[securitygroup]
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
enable_security_group = True
EOF

echo "########## KHOI DONG LAI NOVA ##########"
service nova-api restart
service nova-scheduler restart
service nova-conductor restart

echo "########## KHOI DONG LAI NEUTRON ##########"
service neutron-server restart
echo "=====> Da cai xong phan nay"



