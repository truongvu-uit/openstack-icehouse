#!/bin/bash -ex
#
source general_setup.cfg

echo "Cau hinh hostname cho BLOCK NODE"
sleep 3
echo "block" > /etc/hostname
hostname -F /etc/hostname

ifaces=/etc/network/interfaces
test -f $ifaces.orig || cp $ifaces $ifaces.orig
rm $ifaces
touch $ifaces
cat << EOF >> $ifaces
#Dat IP cho Block node
# LOOPBACK NET
auto lo
iface lo inet loopback
# MGNT NETWORK
auto eth0
iface eth0 inet static
address $BLOCK_MGNT_IP
netmask $NETMASK_ADD
# EXT NETWORK
auto eth1
iface eth1 inet static
address $BLOCK_EXT_IP
netmask $NETMASK_ADD
gateway $GATEWAY_IP
dns-nameservers 8.8.8.8
# DATA NETWORK
auto eth2
iface eth2 inet static
address $BLOCK_DATA_VM_IP
netmask $NETMASK_ADD
EOF

iphost=/etc/hosts
test -f $iphost.orig || cp $iphost $iphost.orig
rm $iphost
touch $iphost
cat << EOF >> $iphost
127.0.0.1 localhost
$CON_MGNT_IP controller
$COM1_MGNT_IP compute
$NET_MGNT_IP network
$BLOCK_MGNT_IP block
EOF

init 6