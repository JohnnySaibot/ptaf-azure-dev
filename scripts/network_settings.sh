#!/bin/bash

HOSTNAME=$1
LICENSE=$2

#delete azcesd if exists
if [ -n "$(apt-cache search azure-security)" ]; then
    apt-get purge -y azure-security
fi

service elasticsearch stop

/usr/lib/jvm/default-java/bin/java -Xms1429560k -Xmx1429560k -Djava.awt.headless=true -XX:+UseParNewGC -XX:+UseConcMarkSweepGC -XX:CMSInitiatingOccupancyFraction=75 -XX:+UseCMSInitiatingOccupancyOnly -XX:+HeapDumpOnOutOfMemoryError -XX:+DisableExplicitGC -Dfile.encoding=UTF-8 -Delasticsearch -Des.pidfile=/var/run/elasticsearch/elasticsearch.pid -Des.path.home=/usr/share/elasticsearch -cp :/usr/share/elasticsearch/lib/elasticsearch-1.7.1.jar:/usr/share/elasticsearch/lib/*:/usr/share/elasticsearch/lib/sigar/* -Des.default.config=/etc/elasticsearch/elasticsearch.yml -Des.default.path.home=/usr/share/elasticsearch -Des.default.path.logs=/var/log/elasticsearch -Des.default.path.data=/var/lib/elasticsearch -Des.default.path.work=/tmp/elasticsearch -Des.default.path.conf=/etc/elasticsearch org.elasticsearch.bootstrap.Elasticsearch &
PID=$!

sleep 20
kill -9 $PID

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
user activate apic

config commit
config sync

EOF

chmod +x ./ptaf_api_settings.py
./ptaf_api_settings.py

echo 'db.users.update({login: "apic"}, {$set: {active: "false"}})' \
   | mongo waf -u root -p $(/usr/local/bin/wsc -c "password list") --authenticationDatabase admin

sleep 20
while [ $(ps aux | grep "/usr/bin/uwsgi --ini /usr/share/uwsgi/conf/default.ini --xmlconfig /etc/uwsgi/apps-enabled/ui.xml --daemonize /var/log/uwsgi/app/ui.log" | wc -l) -lt 5 ]nano; do
    sleep 1
done

echo "ui service is up"

if [ -n "${LICENSE}" ]; then
    curl -k "https://localhost:8443/license/get_config/?license_token=${LICENSE}" || exit 0
fi

