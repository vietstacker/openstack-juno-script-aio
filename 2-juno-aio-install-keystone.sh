#!/bin/bash -ex

source config.cfg

echo "##### START INSTALLING KEYSTONE ##### "
sleep 3

apt-get install keystone python-keystoneclient -y

#/* Back up before editing nova.conf
filekeystone=/etc/keystone/keystone.conf
test -f $filekeystone.orig || cp $filekeystone $filekeystone.orig

echo " ##### EDITING CONFIG FILE /etc/keystone/keystone.conf ##### "
sleep 3
cat << EOF > $filekeystone
[DEFAULT]
admin_token=$SERVICE_PASSWORD
public_bind_host=0.0.0.0
admin_bind_host=0.0.0.0
compute_port=8774
admin_port=35357
public_port=5000
verbose=True
log_dir=/var/log/keystone
[assignment]
[auth]
[cache]
[catalog]
[credential]
[database]
connection = mysql://keystone:$MYSQL_PASS@$MASTER/keystone
idle_timeout=3600
[ec2]
[endpoint_filter]
[federation]
[identity]
[kvs]
[ldap]
[matchmaker_ring]
[memcache]
[oauth1]
[os_inherit]
[paste_deploy]
[policy]
[revoke]
[signing]
[ssl]
[stats]
[token]
[trust]
[extra_headers]
Distribution = Ubuntu

EOF

echo " ##### SETUP KEYSTONE DB ##### "
sleep 3
keystone-manage db_sync

echo "##### DELETE KEYSTONE DEFAULT DB ##### "
sleep 3
rm  /var/lib/keystone/keystone.db

echo "##### RESTARTING KEYSTONE ##### "
service keystone restart
sleep 3
service keystone restart

(crontab -l -u keystone 2>&1 | grep -q token_flush) || \
echo '@hourly /usr/bin/keystone-manage token_flush >/var/log/keystone/keystone-tokenflush.log 2>&1' >> /var/spool/cron/crontabs/keystone

export OS_SERVICE_TOKEN=$TOKEN_PASS
export OS_SERVICE_ENDPOINT=http://$MASTER:35357/v2.0

# echo "##### VALIDATE KEYSTONE SETUP ##### "
# keystone user-list
# sleep 3

echo "##### COMPLETE KEYSTONE INSTALLING & CONFIGURING #####"

