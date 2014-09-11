#!/bin/bash -ex
#
source general_setup.cfg
echo "=====> Dang dong bo"
sleep 3
su -s /bin/sh -c "glance-manage db_sync" glance
sleep 10
echo "=====> Da dong bo xong"
keystone user-create --name=glance --pass=GLANCE_PASS --email=glance@example.com
keystone user-role-add --user=glance --tenant=service --role=admin
keystone service-create --name=glance --type=image --description="OpenStack Image Service"
keystone endpoint-create --service-id=$(keystone service-list | awk '/ image / {print $2}') --publicurl=http://controller:9292 --internalurl=http://controller:9292 --adminurl=http://controller:9292

service glance-registry restart
service glance-api restart
echo "=====> Da khoi dong lai"
sleep 10


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

#Verify the Image Service installation
mkdir /tmp/images
cd /tmp/images/
wget http://cdn.download.cirros-cloud.net/0.3.2/cirros-0.3.2-x86_64-disk.img 

glance image-create --name "cirros-0.3.2-x86_64" --disk-format qcow2 --container-format bare --is-public True --progress < cirros-0.3.2-x86_64-disk.img
glance image-list
rm -r /tmp/images
echo "=====> DA CAI XONG PHAN NAY"














