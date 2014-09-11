#!/bin/bash -ex
source general_setup.cfg

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
address $CON_MGNT_IP
netmask $NETMASK_ADD

# EXT NETWORK
auto eth1
iface eth1 inet static
address $CON_EXT_IP
netmask $NETMASK_ADD
gateway $GATEWAY_IP
dns-nameservers 8.8.8.8
EOF

hosts=/etc/hosts
test -f $hosts.orig || cp $hosts $hosts.orig
rm $hosts
touch $hosts
cat << EOF >> $hosts
127.0.0.1 localhost
$CON_MGNT_IP controller
$NET_MGNT_IP network
$COM_MGNT_IP compute
$BLOCK_MGNT_IP block
EOF

echo "=====>Cau hinh hostname cho CONTROLLER NODE"
sleep 3
echo "controller" > /etc/hostname
hostname -F /etc/hostname

init 6