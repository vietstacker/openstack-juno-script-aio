#!/bin/bash -ex

source config.cfg

echo "########## INSTALLING AND CONFIGURING Open-vSwitch ##########"
# apt-get install -y openvswitch-controller openvswitch-switch openvswitch-datapath-dkms
apt-get install -y  openvswitch-switch neutron-plugin-ml2 neutron-plugin-openvswitch-agent


echo "########## CONFIGURING br-int AND br-ex FOR OpenvSwitch ##########"
sleep 5
ovs-vsctl add-br br-int
ovs-vsctl add-br br-ex
ovs-vsctl add-port br-ex eth0

echo "########## CONFIGURING IP FOR br-ex ##########"

ifaces=/etc/network/interfaces
test -f $ifaces.orig1 || cp $ifaces $ifaces.orig1
rm $ifaces
cat << EOF > $ifaces
# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto br-ex
iface br-ex inet static
address $MASTER
netmask 255.255.255.0
gateway $GATEWAY_IP
dns-nameservers 8.8.8.8

auto eth0
iface eth0 inet manual
   up ifconfig \$IFACE 0.0.0.0 up
   up ip link set \$IFACE promisc on
   down ip link set \$IFACE promisc off
   down ifconfig \$IFACE down

auto eth1
iface eth1 inet static
address $LOCAL_IP
netmask 255.255.255.0

# auto eth2
# iface eth2 inet static
# address 192.168.100.10
#netmask 255.255.255.0
EOF

echo "##########  RESTARTING AFTER CONFIGURING IP ADDRESS ##########"
init 6
