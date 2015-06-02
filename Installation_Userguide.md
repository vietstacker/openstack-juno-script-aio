Openstack Juno AIO Installation User guide on Ubuntu 14.04

# I. LAB information
- Installing Openstack Juno on Ubuntu 14.04 using vmware-workstation.
- Openstack Elements that are going to be installed: Keystone, Glance, Nova (using KVM), Neutron, Horizon.
- Neutron uses ML2 plugin, GRE and use cases for model network is per-tenant per-router.
- virtual machine uses 2 NICs, Eth0 for External, API, MGNT and Eth1 for Internal.

# II. Steps in installation
## 1. Installing Ubuntu 14.04 within Vmware Workstation

Configurations of Ubuntu Server 14.04 within VMware Workstation or physical machine:
- RAM 4GB
- 1st HDD (sda) 60GB installing Ubuntu server 14.04
- 2nd HDD (sdb): Volume for CINDER
- 3rd HDD (sdc): Using for SWIFT
- NIC 1st : External - Using Bridge mode - IP range: 192.168.1.0/24 - Gateway 192.168.1.1
- NIC 2nd : Inetnal VM - Using vmnet4 mode (Need setting up in VMware Workstation before installing Ubuntu - IP range: 192.168.10.0/24)

| NIC 	       | IP ADDRESS     |  SUBNET MASK  | GATEWAY       | DNS     |                   Note               |
| -------------|----------------|---------------|---------------|-------  |--------------------------------------| 
| NIC 1 (eth0) | 192.168.1.xxx  | 255.255.255.0 | 192.168.1.1   | 8.8.8.8 | Bridge in VMware Workstation      |
| NIC 2 (eth1) | 192.168.10.xxx | 255.255.255.0 |    NULL       |   NULL  | Using VMnet4 in Vmware Workstation |



- Password for all services: Welcome123
- Installing under the "root" authority

- Ubuntu server configuration:

<img src=http://i.imgur.com/NpiF3HF.png width="60%" height="60%" border="1">

- Vmware workstation network configuration: 

<img src=http://i.imgur.com/pNg16qO.png width="60%" height="60%" border="1">

## 2. Script Implementation.
- Edit network file  `/etc/network/interfaces` , the same picture: 
<img src=http://i.imgur.com/P4HFa5z.png width="60%" height="60%" border="1">

- Clone installation scripts from github and provide permission for them:
```sh
    apt-get update

    apt-get install git -y
	
    git clone https://github.com/vietstacker/openstack-juno-script-aio.git
    
    cd openstack-juno-script-aio
    
    chmod +x *.sh
```

### 2.0 System updating and re-installing.

Configuring name, file hosts and ip addresses of NICs:
```sh
    bash 0-juno-aio-prepare.sh    
```
After finishing, system will restart.

### 2.1 Installing MARIADB and creating DB for elements.

    cd openstack-juno-script-aio

Installing MYSQL, creating DB for Keystone, Glance, Nova, Neutron:
    
    bash 1-juno-aio-install-mysql.sh    


### 2.2 KEYSTONE Installation.

Configuring keystone.conf file:

    bash 2-juno-aio-install-keystone.sh

### 2.3 User, role, tenant, endpoint declaration.

User, role, tenant, endpoint declaration for services in Openstack:

    bash 3-juno-aio-creatusetenant.sh

Unset the environment variables:

    unset OS_SERVICE_ENDPOINT OS_SERVICE_TOKEN

Execute command "source /etc/profile" to re-create the environment variables:

    source /etc/profile
   
### 2.4 GLANCE Installation. 

Install Glance and add image "cirros" to check the operation of Glance after installing:

    bash 4-juno-aio-install-glance.sh

### 2.5 NOVA Installation.

    bash 5-juno-aio-install-nova.sh

If there appears the following window when configuring libguestfs0 packages then choose "yes"

<img src=http://i.imgur.com/iIggDlR.png width="60%" height="60%">

### 2.6 CINDER Installation.

    bash 6-juno-aio-install-cinder.sh
   
### 2.7 OpenvSwitch Installation and Configuring br-int, br-ex.

    bash 7-juno-aio-config-ip-neutron.sh
  
### 2.8 NEUTRON Installation.

Installing  Neutron Server, ML, L3-agent, DHCP-agent, metadata-agent:

Note: Login under the "root" permission.

    cd openstack-juno-script-aio
    bash 8-juno-aio-install-neutron.sh


### 2.9 HORIZON Installation.

    bash 9-juno-aio-install-horizon.sh

### 2.10 Creating subnet, router for tenant.

Creating subnets for Public Network and Private Network in tenant ADMIN:

    bash create-network.sh

# III. Using Dashboard (Horizon).

Access into dashboard by IP http://IP_ADDRESS_External/horizon

	User: admin or demo
	Pass: OpenStack123
