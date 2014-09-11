#!/bin/bash -ex
source general_setup.cfg

echo "Cau hinh hostname cho COMPUTE NODE"
sleep 3
echo "compute" > /etc/hostname
hostname -F /etc/hostname

ifaces=/etc/network/interfaces
test -f $ifaces.orig || cp $ifaces $ifaces.orig
rm $ifaces
touch $ifaces
cat << EOF >> $ifaces
#Dat IP cho Controller node
# LOOPBACK NET
auto lo
iface lo inet loopback
# MGNT NETWORK
auto eth0
iface eth0 inet static
address $COM_MGNT_IP
netmask $NETMASK_ADD
# EXT NETWORK
auto eth1
iface eth1 inet static
address $COM_EXT_IP
netmask $NETMASK_ADD
gateway $GATEWAY_IP
dns-nameservers 8.8.8.8
# DATA NETWORK
auto eth2
iface eth2 inet static
address $COM_DATA_VM_IP
netmask $NETMASK_ADD
EOF

init 6