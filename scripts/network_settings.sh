#!/bin/bash

HOSTNAME=$1
LICENSE=$2

#delete azcesd if exists
if [ -n "$(apt-cache search azure-security)" ]; then
    apt-get purge -y azure-security
fi

rm /opt/waf/conf/wsc/snapshots/default.sqlite3 || echo 'wsc snapshot does not exist'
rm /opt/waf/conf/wsc/config.sqlite3 || echo 'wsc snapshot does not exist'

# we need old hostname for rabbitwork
hostnamectl set-hostname 'ptaf-vm'
systemctl restart rabbitmq-server.service

WSC_MGMT_INTERFACE=eth0 WSC_WAN_INTERFACE=eth0 WSC_LAN_INTERFACE=eth1 \
/usr/local/bin/wsc -e <<EOF

host add 127.0.1.1 $HOSTNAME
hostname $HOSTNAME

if mode eth0 dhcp
if mode eth1 dhcp

if mark eth0
if mark eth1
if mark lo:0

feature set azure_byol true
integration_mode reverse_proxy

config commit
config sync

EOF

if [ -n "${LICENSE}" ]; then
    curl -k "https://localhost:8443/license/get_config/?license_token=${LICENSE}" || exit 0
fi

