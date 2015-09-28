#!/bin/bash


source ../tests.sh
source ../utils.sh

function install_apache {
	vagrant ssh -c "sudo yum -y install epel-release"
	execute_cmd vagrant ssh -c "sudo yum -y install httpd"
	execute_cmd vagrant ssh -c "sudo service httpd start"
}

function install_nginx {
	vagrant ssh -c "sudo yum -y install epel-release"
	execute_cmd vagrant ssh -c "sudo yum -y install nginx"
	execute_cmd vagrant ssh -c "sudo /etc/init.d/nginx start || sudo service nginx start"

	if [[ $1 == "create_traffic" ]]; then
		execute_cmd vagrant ssh -c "curl -H "Host:sub.domain.com" 127.0.0.1 > /dev/null"
	fi
}

function install_mysql {
	execute_cmd vagrant ssh -c "sudo yum -y install mysql-server"
	execute_cmd vagrant ssh -c "sudo yum -y install git"
	execute_cmd vagrant ssh -c "sudo /sbin/service mysqld start"
	execute_cmd vagrant ssh -c "git clone https://github.com/datacharmer/test_db.git"
	execute_cmd vagrant ssh -c "echo 'general_log_file = /var/log/mysql/mysql.log' | sudo tee -a /etc/my.cnf"
	execute_cmd vagrant ssh -c "echo 'general_log= 1' | sudo tee -a /etc/my.cnf"
	execute_cmd vagrant ssh -c "echo 'log_slow_queries = /var/log/mysql/mysql-slow.log' | sudo tee -a /etc/my.cnf"
	execute_cmd vagrant ssh -c "echo 'long_query_time = 1' | sudo tee -a /etc/my.cnf"
	execute_cmd vagrant ssh -c "echo 'log-queries-not-using-indexes = 1' | sudo tee -a /etc/my.cnf"
	execute_cmd vagrant ssh -c "cd test_db;mysql -u root -p123456 < employees.sql"
	execute_cmd vagrant ssh -c "cd test_db;mysql -u root -p123456 -t < test_employees_md5.sql"
	execute_cmd vagrant ssh -c "cd test_db;mysql -u root -p123456 employees -e 'SELECT * FROM employees LIMIT 10;'"
	execute_cmd vagrant ssh -c "cd test_db;mysql -u root -p123456 employees -e 'SELECT * FROM employees;'"
}

function upgrade_rsyslog {
	execute_cmd vagrant ssh -c "sudo yum -y install wget"
	execute_cmd vagrant ssh -c "cd /etc/yum.repos.d/; sudo wget http://rpms.adiscon.com/v8-stable/rsyslog.repo"
	execute_cmd vagrant ssh -c "sudo yum -y install rsyslog"
	execute_cmd vagrant ssh -c "sudo yum update rsyslog"
	execute_cmd vagrant ssh -c "sudo /etc/init.d/rsyslog restart"
}

function uninstall_rsyslog {
	execute_cmd vagrant ssh -c "sudo yum -y remove rsyslog"
}

function remvoe_rsyslog_service {
	execute_cmd vagrant ssh -c "sudo rm -f /etc/init.d/rsyslog"
}

function disable_traffic {
	execute_cmd vagrant ssh -c "sudo iptables -A OUTPUT -p tcp --dport 5000 -j DROP"
}

function remvoe_apache_service {
	execute_cmd vagrant ssh -c "sudo rm -f /etc/init.d/httpd"
}

function remvoe_nginx_service {
	execute_cmd vagrant ssh -c "sudo rm -f /etc/init.d/nginx"
}

function delete_apache_logs {
	execute_cmd vagrant ssh -c "sudo rm -fr /var/log/httpd"
}

function delete_nginx_logs {
	execute_cmd vagrant ssh -c "sudo rm -fr /var/log/nginx"
}

function copy_apache_logs {
	execute_cmd vagrant ssh -c "sudo mkdir -p ~/var/log/httpd"
	execute_cmd vagrant ssh -c "sudo cp -fr /var/log/httpd ~/var/log/"
}

function copy_nginx_logs {
	execute_cmd vagrant ssh -c "sudo mkdir -p ~/var/log/nginx"
	execute_cmd vagrant ssh -c "sudo cp -fr /var/log/nginx ~/var/log/"
}

function test_file_path {
	run_logz "-t file -tag httpd -p /var/log/httpd/"
}
