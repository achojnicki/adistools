#!/bin/bash

if [ "$EUID" -ne 0 ]
  then 
  	echo "This script must be run as root"
  exit
fi

red='\033[0;31m'
green='\033[0;32m'
nc='\033[0m'

run() {
	prompt_char='#'

	command=$*
	output=`$* 2>&1`
	exit_code=$?

	echo $prompt_char $command
	
	
	if [ $exit_code != 0 ] 
	then 
		echo Output: $output
  		echo -e Status: ${red}Failed${nc}
  	else
  		echo -e Status: ${green}Success${nc}
	fi
	echo ----------


}

echo 'Installing adistools...'
run cd /opt/adistools

echo "Updating $PATH"
export PATH=$PATH:/sbin:/usr/sbin:/usr/local/sbin

echo "Updating local APT cache"
run "apt-get update"

echo "1st stage installation of dependecies"
run "apt-get install curl gnupg apt-transport-https python3 python3-pip nginx redis curl -y"

echo "2nd stage installation of dependecies"
run "pip3 install --break-system-packages flask flask-socketio python-socketio psutil tabulate colored pymongo pyyaml pika redis uwsgi"

echo "Downloading and instaling MongoDB key"
curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-8.0.gpg

echo "Adding MongoDB APT repository"
echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main" | tee /etc/apt/sources.list.d/mongodb-org-8.0.list

echo "Updating local APT cache"
run "apt-get update"

echo "Installing MongoDB database"
run "apt-get install -y mongodb-org"

echo "Enabling MongoDB service"
run "systemctl enable mongod.service"

echo "Staring MongoDB service"
run "service mongod.service start"

echo "Downloading and installing RabbitMQ main signing key"
curl -1sLf 'https://keys.openpgp.org/vks/v1/by-fingerprint/0A9AF2115F4687BD29803A206B73A36E6026DFCA' |gpg --dearmor | tee /usr/share/keyrings/com.rabbitmq.team.gpg >/dev/null

echo "Downloading and installing RabbitMQ 2nd key"
curl -1sLf https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-erlang.E495BB49CC4BBE5B.key |gpg --dearmor | sudo tee /usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg >/dev/null

echo "Downloading and installing RabbitMQ  3rd key"
curl -1sLf https://github.com/rabbitmq/signing-keys/releases/download/3.0/cloudsmith.rabbitmq-server.9F4587F226208342.key |gpg --dearmor | sudo tee /usr/share/keyrings/rabbitmq.9F4587F226208342.gpg> /dev/null

echo "Installing Erlang and RabbitmMQ Repositories"
sudo tee /etc/apt/sources.list.d/rabbitmq.list <<EOF
## Provides modern Erlang/OTP releases
##
deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-erlang/deb/ubuntu noble main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-erlang/deb/ubuntu noble main

# another mirror for redundancy
deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa2.rabbitmq.com/rabbitmq/rabbitmq-erlang/deb/ubuntu noble main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.E495BB49CC4BBE5B.gpg] https://ppa2.rabbitmq.com/rabbitmq/rabbitmq-erlang/deb/ubuntu noble main

## Provides RabbitMQ
##
deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-server/deb/ubuntu noble main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa1.rabbitmq.com/rabbitmq/rabbitmq-server/deb/ubuntu noble main

# another mirror for redundancy
deb [arch=amd64 signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa2.rabbitmq.com/rabbitmq/rabbitmq-server/deb/ubuntu noble main
deb-src [signed-by=/usr/share/keyrings/rabbitmq.9F4587F226208342.gpg] https://ppa2.rabbitmq.com/rabbitmq/rabbitmq-server/deb/ubuntu noble main
EOF

echo "Updating local APT cache"
run "apt-get update"

echo "Installing Erlang"
run "apt-get install -y erlang-base erlang-asn1 erlang-crypto erlang-eldap erlang-ftp erlang-inets erlang-mnesia erlang-os-mon erlang-parsetools erlang-public-key erlang-runtime-tools erlang-snmp erlang-ssl erlang-syntax-tools erlang-tftp erlang-tools erlang-xmerl"

echo "Installing RabbitMQ"
run "apt-get install rabbitmq-server -y --fix-missing"

echo "Creating RabbitMQ users"
run "rabbitmqctl add_user adistools-concurrent password"
run "rabbitmqctl add_user adistools-api password"
run "rabbitmqctl add_user adistools-img_gen password"
run "rabbitmqctl add_user adistools-log_worker password"
run "rabbitmqctl add_user adistools-pixel_tracker password"
run "rabbitmqctl add_user adistools-resp_get password"
run "rabbitmqctl add_user adistools-url_shortener password"
run "rabbitmqctl add_user adistools-wallfaker password"
run "rabbitmqctl add_user sicken-api password"
run "rabbitmqctl add_user sicken-socketio_dispatcher password"
run "rabbitmqctl add_user sicken-worker_commands password"
run "rabbitmqctl add_user sicken-worker_gpt2 password"
run "rabbitmqctl add_user sicken-worker_t5 password"
run "rabbitmqctl add_user yuki-director password"
run "rabbitmqctl add_user yuki-image_generator password"
run "rabbitmqctl add_user yuki-speech_generator password"
run "rabbitmqctl add_user yuki-supervisor password"
run "rabbitmqctl add_user yuki-video_renderer password"

echo "Setting RabbitMQ users permissions"
run "rabbitmqctl set_permissions -p / adistools-concurrent '.*' '.*' '.*'"
run "rabbitmqctl set_permissions -p / adistools-api '.*' '.*' '.*'"
run "rabbitmqctl set_permissions -p / adistools-img_gen '.*' '.*' '.*'"
run "rabbitmqctl set_permissions -p / adistools-log_worker '.*' '.*' '.*'"
run "rabbitmqctl set_permissions -p / adistools-pixel_tracker '.*' '.*' '.*'"
run "rabbitmqctl set_permissions -p / adistools-resp_get '.*' '.*' '.*'"
run "rabbitmqctl set_permissions -p / adistools-url_shortener '.*' '.*' '.*'"
run "rabbitmqctl set_permissions -p / adistools-wallfaker '.*' '.*' '.*'"
run "rabbitmqctl set_permissions -p / sicken-api '.*' '.*' '.*'"
run "rabbitmqctl set_permissions -p / sicken-socketio_dispatcher '.*' '.*' '.*'"
run "rabbitmqctl set_permissions -p / sicken-worker_commands '.*' '.*' '.*'"
run "rabbitmqctl set_permissions -p / sicken-worker_gpt2 '.*' '.*' '.*'"
run "rabbitmqctl set_permissions -p / sicken-worker_t5 '.*' '.*' '.*'"
run "rabbitmqctl set_permissions -p / yuki-director '.*' '.*' '.*'"
run "rabbitmqctl set_permissions -p / yuki-image_generator '.*' '.*' '.*'"
run "rabbitmqctl set_permissions -p / yuki-speech_generator '.*' '.*' '.*'"
run "rabbitmqctl set_permissions -p / yuki-supervisor '.*' '.*' '.*'"
run "rabbitmqctl set_permissions -p / yuki-video_renderer '.*' '.*' '.*'"

echo "Enable RabbitMQ Managment plugin"
run "rabbitmq-plugins enable rabbitmq_management"

echo "Installing adistools sites"
run "ln -s /opt/adistools/nginx_sites/* /etc/nginx/sites-enabled/"

echo "Restarting NGINX"
run "service nginx restart"

echo "Adding adistools service"
run "ln -s /opt/adistools/systemd/adistools.service /lib/systemd/system/"

echo "Reloading daemons database"
run "systemctl daemon-reload"

echo "Enable adistools service"
run "systemctl enable adistools.service"

echo "Start adistools daemon"
run "service adistools start"

echo "Installation complete"   