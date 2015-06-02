#!/bin/bash -ex

echo "########## SETUP POLICY RULES ##########"

nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
nova secgroup-add-rule default tcp 1 65535 0.0.0.0/0
nova secgroup-add-rule default udp 1 65535 0.0.0.0/0

#############
# PROVIDER
#############

echo "########## CREATE NETWORK FOR PROVIDER (EXTENAL) ##########"
sleep 3
neutron net-create ext_net --router:external True --shared 

echo "########## CREATE SUBNET EXTENAL ##########"
sleep 3
neutron subnet-create --name sub_ext_net ext_net 192.168.1.0/24 --gateway 192.168.1.1 --allocation-pool start=192.168.1.150,end=192.168.1.220 --enable_dhcp=False --dns-nameservers list=true 8.8.8.8 8.8.4.4 210.245.0.11


####################
# Network cho tenant
####################

echo "########## CREATE NETWORK FOR TENANT ##########"
sleep 3
neutron net-create int_net 

echo "########## CREATE SUBNET FOR NETWORK IN TENANT ##########"
sleep 3
neutron subnet-create int_net --name int_subnet --dns-nameserver 8.8.8.8 172.16.10.0/24


#####################
# CREATE ROUTER, ASSIGN NETWORK, INTERFACE
#####################

echo "########## CREATE ROUTER ##########"
sleep 3
neutron router-create router_1

echo "########## SETUP DEFAULT GATEWAY FOR ROUTER ##########"
sleep 3
neutron router-gateway-set router_1 ext_net

echo "########## ASSIGN TENANT'S NETWORK FOR ROUTER ##########"
sleep 3
neutron router-interface-add router_1 int_subnet


# LAY ID cua subnet internal  
ID_int_net=`neutron net-list | awk '/int*/ {print $2}'`
# echo $ID_int_net


echo "########## CREATE VM NAME vm6969 FOR TESTING ##########"
nova boot vm6969 --image cirros-0.3.2-x86_64 --flavor 1 --security-groups default --nic net-id=$ID_int_net

echo "########## CHECKING .. ##########"
sleep 10
nova list 
# Tao flavor or example, create a new flavor called m1.custom with an ID of 6, 512 MB of RAM, 5 GB of root disk space, and 1 vCPU:

# echo "########## Tao flavor co ID la 6 , RAM 512Mb, HDD 5Gb, CPU 1##########"
# nova flavor-create m1.custom 6 512 5 1

# LAY ID cua subnet internal  
# ID_int_net=`neutron net-list | awk '/int*/ {print $2}'`
# echo $ID_int_net

