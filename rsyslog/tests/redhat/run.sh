#!/bin/bash

# -----------------------
# Utils
# -----------------------
source ./utils.sh


# -----------------------
# Run
# -----------------------

pushd ../.. > /dev/null
	dists=("chef/centos-6.5" "chef/centos-6.6" "chef/centos-7.0" "chef/fedora-20" "chef/fedora-21" "chef/fedora-19")

	for dist in ${dists[@]}; do
		export VAGRANT_BOX="$dist"

		echo "------------------------------------------------------------" 
		echo "DEBUG" "Using DISTRABUTION: $dist"
		echo "------------------------------------------------------------" 
		
		execute_success_test test_configure_rsyslog
		execute_success_test test_configure_rsyslog_uninstalled
		execute_fail_test test_configure_rsyslog_on_network

		execute_success_test test_configure_apache
		execute_success_test test_configure_apache_custom_logs "error_log" "access_log"
		
		execute_success_test test_configure_nginx
		execute_success_test test_configure_nginx_custom_logs
		
		execute_success_test test_configure_file
		execute_success_test test_configure_json_file
		#execute_success_test test_configure_mysql
	done
	
popd > /dev/null
