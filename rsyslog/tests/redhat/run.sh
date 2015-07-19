#!/bin/bash

# -----------------------
# Utils
# -----------------------
source ./utils.sh


# -----------------------
# Run
# -----------------------

pushd ../.. > /dev/null
	dists=("chef/centos-6.5" "chef/centos-7.0" "chef/centos-6.6" "puppetlabs/centos-6.6-32-nocm" "chef/fedora-20" "chef/fedora-21" "chef/fedora-19")

	for dist in ${dists[@]}; do
		export VAGRANT_BOX="$dist"

		echo "------------------------------------------------------------" 
		echo "DEBUG" "Using DISTRABUTION: $dist"
		echo "------------------------------------------------------------" 
		
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
	
popd > /dev/null
