#!/bin/bash -ex 

source config.cfg

echo "########## CONFIGURING STATIC IP FOR NICs ##########"

ifaces=/etc/network/interfaces
test -f $ifaces.orig || cp $ifaces $ifaces.orig
rm $ifaces
cat << EOF > $ifaces
#Configuring IP for Controller node

# LOOPBACK NET 
auto lo
iface lo inet loopback

# EXT NETWORK
auto eth0
iface eth0 inet static
address $MASTER
netmask 255.255.255.0
gateway $GATEWAY_IP
dns-nameservers 8.8.8.8

# DATA NETWORK
auto eth1
iface eth1 inet static
address $LOCAL_IP
netmask 255.255.255.0

EOF

/etc/init.d/networking restart 

echo "########## ADDING JUNO's REPO ##########"

# apt-get install ubuntu-cloud-keyring python-setuptools python-iniparse python-psutil -y
# echo deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/juno main >> /etc/apt/sources.list.d/juno.list

# apt-get install python-software-properties -y
# add-apt-repository cloud-archive:juno -y 

apt-get install python-software-properties
echo deb http://ubuntu-cloud.archive.canonical.com/ubuntu trusty-updates/juno main >> /etc/apt/sources.list.d/ubuntu-cloud-archive-juno-trusty.list
apt-get install ubuntu-cloud-keyring
 
# apt-get install python-software-properties -y
# add-apt-repository cloud-archive:juno -y 

# apt-get install python-software-properties -y
# add-apt-repository ppa:ubuntu-cloud-archive/juno-staging -y

sudo apt-get update && sudo apt-get -y upgrade && sudo apt-get -y dist-upgrade 

iphost=/etc/hosts
test -f $iphost.orig || cp $iphost $iphost.orig
rm $iphost

echo "########## SETUP HOTSNAME, IP ADDRESS for UBUNTU ##########"

hostname controller
echo "controller" > /etc/hostname

# AIO model should use loopback IP
cat << EOF >> $iphost
127.0.0.1       localhost
127.0.1.1       controller
$eth0_address	controller
$eth1_address	controller
 
# The following lines are desirable for IPv6 capable hosts
# ::1     ip6-localhost ip6-loopback
# fe00::0 ip6-localnet
# ff00::0 ip6-mcastprefix
# ff02::1 ip6-allnodes
# ff02::2 ip6-allrouters
EOF

# Editing hosts file does not require network restart
# /etc/init.d/networking restart 

# Enable IP forwarding
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
echo "net.ipv4.conf.all.rp_filter=0" >> /etc/sysctl.conf
echo "net.ipv4.conf.default.rp_filter=0" >> /etc/sysctl.conf
sysctl -p

echo "########## INSTALL & CONFIG NTP ##########"
sleep 3
apt-get install -y ntp

# Config NTP in Ice House
# sed -i 's/server ntp.ubuntu.com/ \
# server ntp.ubuntu.com \
# server 127.127.1.0 \
# fudge 127.127.1.0 stratum 10/g' /etc/ntp.conf

## Config NTP in JUNO
sed -i 's/server ntp.ubuntu.com/ \
server 0.vn.pool.ntp.org iburst \
server 1.asia.pool.ntp.org iburst \
server 2.asia.pool.ntp.org iburst/g' /etc/ntp.conf

sed -i 's/restrict -4 default kod notrap nomodify nopeer noquery/ \
#restrict -4 default kod notrap nomodify nopeer noquery/g' /etc/ntp.conf

sed -i 's/restrict -6 default kod notrap nomodify nopeer noquery/ \
restrict -4 default kod notrap nomodify \
restrict -6 default kod notrap nomodify/g' /etc/ntp.conf


echo "########## RESTARTING NTP SERVICE ##########"
sleep 3
service ntp restart


echo "########## INSTALLING RABBITMQ SERVICE ##########"
sleep 3
apt-get -y install rabbitmq-server

echo "########## SETTING UP PASSWORD FOR RABBITMQ ##########"
# sleep 3
rabbitmqctl change_password guest $RABBIT_PASS
echo "########## NOW REBOOTING SERVER, BYE BYE ##########"
sleep 3
service rabbitmq-server restart
sleep 3
init 6 
