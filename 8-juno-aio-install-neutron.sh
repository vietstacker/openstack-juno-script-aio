#!/bin/bash -ex
source config-after-neutron.cfg

echo "########## SETTING UP NEUTRON CONTROLLER ##########"
apt-get -y install neutron-server neutron-plugin-ml2 neutron-plugin-openvswitch-agent \
neutron-l3-agent neutron-dhcp-agent

######## BACK UP NEUTRON.CONF IN CONTROLLER##################"
echo "########## MODIFYING neutron.conf ##########"

#
controlneutron=/etc/neutron/neutron.conf
test -f $controlneutron.orig || cp $controlneutron $controlneutron.orig
rm $controlneutron
cat << EOF > $controlneutron
[DEFAULT]
verbose = True
lock_path = \$state_path/lock
core_plugin = ml2
service_plugins = router
auth_strategy = keystone
notify_nova_on_port_status_changes = True
notify_nova_on_port_data_changes = True
nova_url = http://$MASTER:8774/v2
nova_region_name = regionOne
nova_admin_username = nova
nova_admin_tenant_id = 43a4e75c335e4ff992630ad37d566b52
nova_admin_password = $ADMIN_PASS
nova_admin_auth_url = http://$MASTER:35357/v2.0
rabbit_host=$MASTER
rabbit_password=$ADMIN_PASS
rpc_backend=rabbit
rabbit_userid = guest

[matchmaker_redis]

[matchmaker_ring]
[quotas]

[agent]
root_helper = sudo /usr/bin/neutron-rootwrap /etc/neutron/rootwrap.conf

[keystone_authtoken]
auth_uri = http://$MASTER:5000/v2.0
identity_uri = http://$MASTER:35357
admin_tenant_name = service
admin_user = neutron
admin_password = $ADMIN_PASS

[database]
connection = mysql://neutron:$ADMIN_PASS@$MASTER/neutron

[service_providers]
service_provider=LOADBALANCER:Haproxy:neutron.services.loadbalancer.drivers.haproxy.plugin_driver.HaproxyOnHostPluginDriver:default
service_provider=VPN:openswan:neutron.services.vpn.service_drivers.ipsec.IPsecVPNDriver:default

EOF

######## BACK-UP ML2 CONFIG IN CONTROLLER##################"
echo "########## MODIFYING ml2_conf.ini ##########"
sleep 7

controlML2=/etc/neutron/plugins/ml2/ml2_conf.ini
test -f $controlML2.orig || cp $controlML2 $controlML2.orig
rm $controlML2

cat << EOF > $controlML2
[ml2]
type_drivers = flat,gre
tenant_network_types = gre
mechanism_drivers = openvswitch

[ml2_type_flat]
flat_networks = external

[ml2_type_vlan]

[ml2_type_gre]
tunnel_id_ranges = 1:1000

[ml2_type_vxlan]

[securitygroup]
enable_security_group = True
enable_ipset = True
firewall_driver = neutron.agent.linux.iptables_firewall.OVSHybridIptablesFirewallDriver

[ovs]
local_ip = $LOCAL_IP
tunnel_type = gre
enable_tunneling = True
bridge_mappings = external:br-ex

EOF

###################### BACK-UP L3 CONFIG ###########################"
echo "########## MODIFYING l3_agent.ini ##########"
sleep 7


l3file=/etc/neutron/l3_agent.ini
test -f $l3file.orig || cp $l3file $l3file.orig
rm $l3file
touch $l3file
cat << EOF >> $l3file
[DEFAULT]
verbose = True 
interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
use_namespaces = True

EOF

######## MODIFYING DHCP CONFIG ##################"
echo "########## MODIFYING DHCP CONFIG ##########"
sleep 7

dhcpfile=/etc/neutron/dhcp_agent.ini 
test -f $dhcpfile.orig || cp $dhcpfile $dhcpfile.orig
rm $dhcpfile
cat << EOF > $dhcpfile
[DEFAULT]
verbose = True 
interface_driver = neutron.agent.linux.interface.OVSInterfaceDriver
dhcp_driver = neutron.agent.linux.dhcp.Dnsmasq
use_namespaces = True

EOF

######## BACK-UP METADATA CONFIG IN CONTROLLER##################"
echo "########## MODIFYING metadata_agent.ini ##########"
sleep 7

metadatafile=/etc/neutron/metadata_agent.ini
test -f $metadatafile.orig || cp $metadatafile $metadatafile.orig
rm $metadatafile
cat << EOF > $metadatafile
[DEFAULT]
verbose = True 
auth_url = http://localhost:5000/v2.0
auth_region = regionOne
admin_tenant_name = service
admin_user = neutron
admin_password = $ADMIN_PASS
nova_metadata_ip = $MASTER
metadata_proxy_shared_secret = $METADATA_SECRET

EOF

chown root:neutron /etc/neutron/*
chown root:neutron $controlML2

su -s /bin/sh -c "neutron-db-manage --config-file /etc/neutron/neutron.conf \
--config-file /etc/neutron/plugins/ml2/ml2_conf.ini upgrade juno" neutron

echo "########## RESTARTING NEUTRON SERVICE ##########"
sleep 5
# for i in $( ls /etc/init.d/neutron-* ); do service `basename $i` restart; done
service neutron-server restart
service neutron-l3-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service openvswitch-switch restart
service neutron-plugin-openvswitch-agent restart


echo "########## RESTARTING NEUTRON (lan2) ##########"
sleep 5
# for i in $( ls /etc/init.d/neutron-* ); do service `basename $i` restart; done
service neutron-server restart
service neutron-l3-agent restart
service neutron-dhcp-agent restart
service neutron-metadata-agent restart
service openvswitch-switch restart
service neutron-plugin-openvswitch-agent restart

# ADDING RESTARTING NEUTRON SERVICE COMMAND EACH TIME RESET OPENSTACK
sed -i "s/exit 0/# exit 0/g" /etc/rc.local
echo "service neutron-server restart"
echo "service neutron-l3-agent restart"
echo "service neutron-dhcp-agent restart"
echo "service neutron-metadata-agent restart"
echo "service openvswitch-switch restart"
echo "service neutron-plugin-openvswitch-agent restart"
echo "exit 0" >> /etc/rc.local


echo "########## TESTING NEUTRON (WAIT 60s)   ##########"
# WAITING FOR NEUTRON BOOT-UP
sleep 60
neutron agent-list
