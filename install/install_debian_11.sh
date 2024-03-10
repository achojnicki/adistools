#!/bin/bash

#!/bin/bash

if [ "$EUID" -ne 0 ]
  then 
  	echo "This script have to be run as root"
  exit
fi

echo 'Installing adistools...'

#changing working directory to the /opt/adistools
cd /opt/adistools

# gnupg for rabbitmq
apt-get install curl apt-transport-https python3 python3-pip nginx uwsgi -y
pip3 install flask flask-socketio python-socketio psutil tabulate colored pymongo pyyaml pytorch transformers[pytorch] datasets pika socket

#rabbitmq and erlang keys
#curl -1sLf "https://keys.openpgp.org/vks/v1/by-fingerprint/0A9AF2115F4687BD29803A206B73A36E6026DFCA" |  gpg --dearmor |  tee /usr/share/keyrings/com.rabbitmq.team.gpg > /dev/null
#curl -1sLf "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xf77f1eda57ebb1cc" |  gpg --dearmor |  tee /usr/share/keyrings/net.launchpad.ppa.rabbitmq.erlang.gpg > /dev/null
#curl -1sLf "https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey" |  gpg --dearmor |  tee /usr/share/keyrings/io.packagecloud.rabbitmq.gpg > /dev/null

#mongo keys
wget -qO - https://www.mongodb.org/static/pgp/server-6.0.asc | apt-key add -

#rabbitmq repo
#tee /etc/apt/sources.list.d/rabbitmq.list <<EOF
### Erlang
#deb [signed-by=/usr/share/keyrings/net.launchpad.ppa.rabbitmq.erlang.gpg] http://ppa.launchpad.net/rabbitmq/rabbitmq-erlang/ubuntu bionic main
#deb-src [signed-by=/usr/share/keyrings/net.launchpad.ppa.rabbitmq.erlang.gpg] http://ppa.launchpad.net/rabbitmq/rabbitmq-erlang/ubuntu bionic main
#
### RabbitMQ
#deb [signed-by=/usr/share/keyrings/io.packagecloud.rabbitmq.gpg] https://packagecloud.io/rabbitmq/rabbitmq-server/ubuntu/ bionic main
#deb-src [signed-by=/usr/share/keyrings/io.packagecloud.rabbitmq.gpg] https://packagecloud.io/rabbitmq/rabbitmq-server/ubuntu/ bionic main
#EOF

#mongo repo
tee /etc/apt/sources.list.d/mongodb-org-6.0.list <<EOF
deb http://repo.mongodb.org/apt/debian bullseye/mongodb-org/6.0 main
EOF

#update database of package manager
apt-get update

#install erlang
#apt-get install -y erlang-base \
#                        erlang-asn1 erlang-crypto erlang-eldap erlang-ftp erlang-inets \
#                        erlang-mnesia erlang-os-mon erlang-parsetools erlang-public-key \
#                        erlang-runtime-tools erlang-snmp erlang-ssl \
#                        erlang-syntax-tools erlang-tftp erlang-tools erlang-xmerl

#install rabbitmq
#apt-get install rabbitmq-server -y --fix-missing

#create rabbitmq account and set permissions
#rabbitmqctl add_user adisconcurrent devpasswd
#rabbitmqctl set_user_tags adisconcurrent administrator
#rabbitmqctl set_permissions -p / adisconcurrent ".*" ".*" ".*"

#enable rabbitmq managment
#rabbitmq-plugins enable rabbitmq_management

#install mongodb
apt-get install -y mongodb-org

#enable start of mongodb on boot
systemctl enable mongod.service

#starting mongodb
servce mongod start

#adding systemd service
ln -s /opt/adistools/systemd/adistools.service /lib/systemd/system/

#reloading daemons database
systemctl daemon-reload

#adding adistools to autostart
systemctl enable adistools.service

#starting adistools service
service adistools start

#adding symlinks to the nginx sites
ln -s /opt/adistools/nginx_sites/adistools-api /etc/nginx/sites-enabled/
ln -s /opt/adistools/nginx_sites/adistools-url_shortener /etc/nginx/sites-enabled/
ln -s /opt/adistools/nginx_sites/adistools-wallfaker /etc/nginx/sites-enabled/

#restaring nginx service
service nginx restart


#adding domains bindings for hosts file
echo "127.0.0.1        adistools-api" >>/etc/hosts
echo "127.0.0.1        adistools-url_shortener" >>/etc/hosts
echo "127.0.0.1        adistools-wallfaker" >>/etc/hosts

