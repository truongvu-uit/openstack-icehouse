#!/bin/bash -ex
#
source general_setup.cfg

iphost=/etc/hosts
test -f $iphost.orig || cp $iphost $iphost.orig
rm $iphost
touch $iphost
cat << EOF >> $iphost
127.0.0.1 localhost
$CON_MGNT_IP controller
$COM1_MGNT_IP compute
$NET_MGNT_IP network
EOF

echo "############ Cai dat NTP va cau hinh can thiet ############ "
apt-get install ntp -y
apt-get install python-mysqldb -y

echo "############ Sao luu cau hinh cua NTP ############ "
cp /etc/ntp.conf /etc/ntp.conf.bka
rm /etc/ntp.conf
cat /etc/ntp.conf.bka | grep -v ^# | grep -v ^$ >> /etc/ntp.conf

sed -i 's/server/#server/' /etc/ntp.conf
echo "server controller" >> /etc/ntp.conf

echo "############ Cau hinh forward goi tin cho cac VM ############"
echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.rp_filter=0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.rp_filter=0" >> /etc/sysctl.conf
sysctl -p

echo "############ Cai cac goi cho network node ############ "
apt-get install neutron-plugin-ml2 neutron-plugin-openvswitch-agent neutron-l3-agent neutron-dhcp-agent -y

echo "############ Sua file cau hinh neutron.conf ############"
netneutron=/etc/neutron/neutron.conf
test -f $netneutron.orig || cp $netneutron $netneutron.orig
rm $netneutron
touch $netneutron
cat << EOF >> $netneutron
[DEFAULT]
auth_strategy = keystone
rpc_backend = neutron.openstack.common.rpc.impl_kombu
rabbit_host = controller
rabbit_password = RABBIT_PASS
core_plugin = ml2
service_plugins = router
allow_overlapping_ips = True
verbose = True
state_path = /var/lib/neutron
lock_path = \$state_path/lock
notification_driver = neutron.openstack.common.notifier.rpc_notifier
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
#connection = sqlite:////var/lib/neutron/neutron.sqlite
[service_providers]
EOF

echo "############ Sua file cau hinh L3 AGENT ############"
netl3agent=/etc/neutron/l3_agent.ini
test -f $netl3agent.orig || cp $netl3agent $netl3agent.orig
rm $netl3agent
touch $netl3agent
cat << EOF >> $netl3agent
[DEFAULT]
interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
use_namespaces = True
verbose = True
EOF

echo "############ Sua file cau hinh DHCP AGENT ############ "
netdhcp=/etc/neutron/dhcp_agent.ini
test -f $netdhcp.orig || cp $netdhcp $netdhcp.orig
rm $netdhcp
touch $netdhcp
cat << EOF >> $netdhcp
[DEFAULT]
interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
use_namespaces = True
verbose = True
EOF

echo "############ Sua file cau hinh METADATA AGENT ############"
netmetadata=/etc/neutron/metadata_agent.ini
test -f $netmetadata.orig || cp $netmetadata $netmetadata.orig
rm $netmetadata
touch $netmetadata
cat << EOF >> $netmetadata
[DEFAULT]
auth_url = http://controller:5000/v2.0
auth_region = regionOne
admin_tenant_name = service
admin_user = neutron
admin_password = NEUTRON_PASS
nova_metadata_ip = controller
metadata_proxy_shared_secret = $METADATA_SECRET
verbose = True
EOF

echo "############ Sua file cau hinh ML2 AGENT ############"
netml2=/etc/neutron/plugins/ml2/ml2_conf.ini
test -f $netml2.orig || cp $netml2 $netml2.orig
rm $netml2
touch $netml2
cat << EOF >> $netml2
[ml2]
type_drivers = gre
tenant_network_types = gre
mechanism_drivers = openvswitch
[ml2_type_flat]
[ml2_type_vlan]
[ml2_type_gre]
tunnel_id_ranges = 1:1000
[ml2_type_vxlan]
[ovs]
local_ip = $NET_DATA_VM_IP
tunnel_type = gre
enable_tunneling = True
[securitygroup]
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver
enable_security_group = True
EOF

echo "############ Khoi dong lai OpenvSwitch ############"
service openvswitch-switch restart
service neutron-plugin-openvswitch-agent restart
service neutron-l3-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart

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


































