#!/bin/bash

# -----------------------
# Utils
# -----------------------

source ./utils.sh



# -----------------------
# Run
# -----------------------

pushd ../.. > /dev/null
	dists=("ubuntu/trusty64") # "ubuntu/precise64")

	for dist in ${dists[@]}; do
		export VAGRANT_BOX="$dist"

		echo "------------------------------------------------------------" 
		echo "DEBUG" "Using DISTRABUTION: $dist"
		echo "------------------------------------------------------------" 
		
#		execute_success_test test_configure_rsyslog
#		execute_success_test test_configure_rsyslog_uninstalled
#		execute_fail_test test_configure_rsyslog_on_network

#		execute_success_test test_configure_apache
#		execute_success_test test_configure_apache_custom_logs "error.log" "access.log"
		
#		execute_success_test test_configure_nginx
#		execute_success_test test_configure_nginx_custom_logs
		
#		execute_success_test test_configure_file
#		execute_success_test test_configure_json_file

		execute_success_test test_configure_mysql --errorlog /var/log/mysql/error.log --generallog /var/log/mysql/mysql.log --slowlog /var/log/mysql/mysql-slow.log
	done
	
popd > /dev/null
