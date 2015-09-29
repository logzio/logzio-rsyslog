#!/bin/bash

# -----------------------
# Tests - rsyslog
# -----------------------


function test_configure_rsyslog {
	# start fresh machine
	fresh_vagrent
	# run rsyslog linux install
	run_logz "-t linux"
}

function test_configure_rsyslog_uninstalled {
	# start fresh machine
	fresh_vagrent
	# delete rsyslog
	uninstall_rsyslog
	# run rsyslog linux install
	run_logz "-t linux"
}


function test_configure_rsyslog_not_a_service {
	# start fresh machine
	fresh_vagrent
	# remove service
	remvoe_rsyslog_service
	# run rsyslog linux install
	run_logz "-t linux"
}

function test_configure_rsyslog_on_network {
	# start fresh machine
	fresh_vagrent
	# prevent outgoing connection to destination on port 5000
	disable_traffic
	# run rsyslog linux install
	run_logz "-t linux"
}


# -----------------------
# Tests - apache
# -----------------------

function test_configure_apache {
	# start fresh machine
	fresh_vagrent
	#install apache and make some network traffic
	install_apache "create_traffic"
	# run rsyslog apache install
	run_logz "-t apache"
}

function test_configure_apache_uninstalled {
	# start fresh machine
	fresh_vagrent
	# run rsyslog apache install
	run_logz "-t apache"

	#should fail: apache hasn't been installed
}

function test_configure_apache_missing_logs {
	# start fresh machine
	fresh_vagrent
	#install apache and make some network traffic
	install_apache "create_traffic"
	#delete logs ...
	delete_apache_logs
	# run rsyslog apache install
	run_logz "-t apache"
}

function test_configure_apache_custom_logs {
	# start fresh machine
	fresh_vagrent
	#install apache and make some network traffic
	install_apache "create_traffic"
	#delete logs ...
	copy_apache_logs
	# run rsyslog apache install
	run_logz "-t apache --errorlog ~/var/log/httpd/$1 --accesslog ~/var/log/httpd/$2"
}

function test_configure_apache_logs_empty {
	# start fresh machine
	fresh_vagrent
	#install apache without network traffic
	install_apache
	# run rsyslog apache install
	run_logz "-t apache"

	# no traffic ...  
}


# -----------------------
# Tests - ngnix
# -----------------------


function test_configure_nginx {
	# start fresh machine
	fresh_vagrent
	#install nginx and make some network traffic
	install_nginx "create_traffic"
	# run rsyslog nginx install
	run_logz "-t nginx"
}

function test_configure_nginx_uninstalled {
	# start fresh machine
	fresh_vagrent
	# run rsyslog nginx install
	run_logz "-t nginx"

	#should fail: nginx hasn't been installed
}

function test_configure_nginx_missing_logs {
	# start fresh machine
	fresh_vagrent
	#install nginx and make some network traffic
	install_nginx "create_traffic"
	#delete logs ...
	delete_nginx_logs
	# run rsyslog nginx install
	run_logz "-t nginx"
}

function test_configure_nginx_custom_logs {
	# start fresh machine
	fresh_vagrent
	#install nginx and make some network traffic
	install_nginx "create_traffic"
	#copy logs ...
	copy_nginx_logs
	# run rsyslog nginx install
	run_logz "-t nginx --errorlog ~/var/log/nginx/error.log --accesslog ~/var/log/nginx/access.log"
}

function test_configure_nginx_logs_empty {
	# start fresh machine
	fresh_vagrent
	#install nginx without network traffic
	install_nginx
	# run rsyslog nginx install
	run_logz "-t nginx"

	# no traffic ...  
}


# -----------------------
# Tests - Mysql
# -----------------------


function test_configure_mysql {
	# start fresh machine
	fresh_vagrent

	#upgrade rsyslog
	upgrade_rsyslog

	#install mysql and make some network traffic
	install_mysql
	# run rsyslog mysql install
	run_logz "-t mysql"
}

# -----------------------
# Tests - File
# -----------------------


function test_configure_file {
	# start fresh machine
	fresh_vagrent
	#install apache and make some network traffic
	install_apache "create_traffic"
	# run rsyslog nginx install
	test_file_path
}



function create_json_file {
    execute_cmd vagrant ssh -c 'echo { "key": "value1"} >> /home/vagrant/simple.json'
    execute_cmd vagrant ssh -c 'echo { "key": "value2"} >> /home/vagrant/simple.json'
    execute_cmd vagrant ssh -c 'echo { "key": "value3"} >> /home/vagrant/simple.json'
    execute_cmd vagrant ssh -c 'echo { "key": "value4"} >> /home/vagrant/simple.json'
    execute_cmd vagrant ssh -c 'echo { "key": "value5"} >> /home/vagrant/simple.json'
    execute_cmd vagrant ssh -c 'echo { "key": "value6"} >> /home/vagrant/simple.json'
    execute_cmd vagrant ssh -c 'echo { "key": "value7"} >> /home/vagrant/simple.json'
}

function test_json_file_path {
	run_logz "-t file -tag myjson -p /home/vagrant/simple.json -c json"
}

function test_configure_json_file {
	# start fresh machine
	fresh_vagrent

	create_json_file

	test_json_file_path
}


