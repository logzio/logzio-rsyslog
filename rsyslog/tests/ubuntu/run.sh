#!/bin/bash

# chef/centos-6.5 # 64 
# chef/centos-7.0
# chef/centos-6.6
# puppetlabs/centos-6.6-32-nocm # 32
# chef/fedora-20
# chef/fedora-21 
# chef/fedora-19


# -----------------------
# Tests - rsyslog
# -----------------------


function test_configure_rsyslog {
	# start fresh machine
	fresh_vagrent
	# run rsyslog linux install
	run_logz "linux"
}

function test_configure_rsyslog_uninstalled {
	# start fresh machine
	fresh_vagrent
	# delete rsyslog
	execute_cmd vagrant ssh -c "sudo apt-get -y remove rsyslog"
	execute_cmd vagrant ssh -c "sudo apt-get -y purge rsyslog"
	# run rsyslog linux install
	run_logz "linux"
}


function test_configure_rsyslog_not_a_service {
	# start fresh machine
	fresh_vagrent
	# remove service
	execute_cmd vagrant ssh -c "sudo rm -f /etc/init.d/rsyslog"
	# run rsyslog linux install
	run_logz "linux"
}

function test_configure_rsyslog_on_network {
	# start fresh machine
	fresh_vagrent
	# prevent outgoing connection to destination on port 5000
	execute_cmd vagrant ssh -c "sudo iptables -A OUTPUT -p tcp --dport 5000 -j DROP"
	# run rsyslog linux install
	run_logz "linux"
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
	run_logz "apache"
}

function test_configure_apache_uninstalled {
	# start fresh machine
	fresh_vagrent
	# run rsyslog apache install
	run_logz "apache"

	#should fail: apache hasn't been installed
}

function test_configure_apache_not_a_service {
	# start fresh machine
	fresh_vagrent
	#install apache and make some network traffic
	install_apache "create_traffic"
	# remove apache service
	execute_cmd vagrant ssh -c "sudo rm -f /etc/init.d/apache2"
	# run rsyslog apache install
	run_logz "apache"
}

function test_configure_apache_missing_logs {
	# start fresh machine
	fresh_vagrent
	#install apache and make some network traffic
	install_apache "create_traffic"
	#delete logs ...
	execute_cmd vagrant ssh -c "sudo rm -fr /var/log/apache2"
	# run rsyslog apache install
	run_logz "apache"
}

function test_configure_apache_logs_empty {
	# start fresh machine
	fresh_vagrent
	#install apache without network traffic
	install_apache
	# run rsyslog apache install
	run_logz "apache"

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
	run_logz "nginx"
}

function test_configure_nginx_uninstalled {
	# start fresh machine
	fresh_vagrent
	# run rsyslog nginx install
	run_logz "nginx"

	#should fail: nginx hasn't been installed
}

function test_configure_nginx_not_a_service {
	# start fresh machine
	fresh_vagrent
	#install nginx and make some network traffic
	install_nginx "create_traffic"
	# remove nginx service
	execute_cmd vagrant ssh -c "sudo rm -f /etc/init.d/nginx"
	# run rsyslog nginx install
	run_logz "nginx"
}

function test_configure_nginx_missing_logs {
	# start fresh machine
	fresh_vagrent
	#install nginx and make some network traffic
	install_nginx "create_traffic"
	#delete logs ...
	execute_cmd vagrant ssh -c "sudo rm -fr /var/log/nginx"
	# run rsyslog nginx install
	run_logz "nginx"
}

function test_configure_nginx_logs_empty {
	# start fresh machine
	fresh_vagrent
	#install nginx without network traffic
	install_nginx
	# run rsyslog nginx install
	run_logz "nginx"

	# no traffic ...  
}



# -----------------------
# Utils
# -----------------------

source ../utils.sh

function install_apache {
	execute_cmd vagrant ssh -c "sudo apt-get update"
	execute_cmd vagrant ssh -c "sudo apt-get -y install apache2"

	if [[ $1 == "create_traffic" ]]; then
		execute_cmd vagrant ssh -c "curl -H "Host:sub.domain.com" 127.0.0.1 > /dev/null"
	fi
}


function install_nginx {
	execute_cmd vagrant ssh -c "sudo apt-get update"
	execute_cmd vagrant ssh -c "sudo apt-get -y install nginx"

	if [[ $1 == "create_traffic" ]]; then
		execute_cmd vagrant ssh -c "curl -H "Host:sub.domain.com" 127.0.0.1 > /dev/null"
	fi
}


# -----------------------
# Run
# -----------------------

pushd ../.. > /dev/null
	dists=("ubuntu/trusty64" "ubuntu/precise64")

	for dist in dists; do
		export VAGRANT_BOX="$dist"
		execute_success_test test_configure_rsyslog
		execute_success_test test_configure_rsyslog_uninstalled
		execute_success_test test_configure_rsyslog_not_a_service
		execute_fail_test test_configure_rsyslog_on_network

		execute_success_test test_configure_apache
		execute_fail_test test_configure_apache_uninstalled
		execute_fail_test test_configure_apache_not_a_service
		# execute_fail_test test_configure_apache_missing_logs

		execute_success_test test_configure_nginx
		execute_fail_test test_configure_nginx_uninstalled
		execute_fail_test test_configure_nginx_not_a_service
		execute_fail_test test_configure_nginx_missing_logs
	done
	
	

	#export VAGRANT_BOX="ubuntu/precise64"
	#execute_cmd configure_apache
	#execute_cmd configure_nginx

popd > /dev/null
