#!/bin/bash

# ---------------------------------------- 
# Setup dependencies
# ---------------------------------------- 
source $LOGZ_DIR/configure_linux.sh "false"



# ---------------------------------------- 
# Setup variables
# ---------------------------------------- 

# The name of the nginx service
NGINX_SERVICE_NAME="nginx"

# The path to the nginx log folder
NGINX_LOGS_DIRECTORY="/var/log/$NGINX_SERVICE_NAME"

# The name of nginx access log file
NGINX_ACCESS_LOG_FILE_NAME="access.log"

# The name of nginx error log file
NGINX_ERROR_LOG_FILE_NAME="error.log"

# The path to nginx error log file
NGINX_ERORR_LOG_PATH=$NGINX_LOGS_DIRECTORY/$NGINX_ERROR_LOG_FILE_NAME

# The path of nginx access log file
NGINX_ACCESS_LOG_PATH=$NGINX_LOGS_DIRECTORY/$NGINX_ACCESS_LOG_FILE_NAME

# The name of logzio syslog conf file
RSYSLOG_NGINX_FILENAME="21-logzio-nginx.conf"


# ---------------------------------------- 
# initiate rsyslog nginx conf installation
# and validate compatibility 
# ---------------------------------------- 
function install_rsyslog_nginx_conf {
	# initiate rsyslog conf installation and validate compatibility 
	install_rsyslog_conf

	log "INFO" "Install nginx rsyslog config"
	# validate nginx compatibility requirements are reached.
	validate_nginx_compatibility

	# create the rsyslog config file
	write_nginx_conf

	# validate that logs are been sent
	validate_rsyslog_logzio_installation ${RSYSLOG_NGINX_FILENAME}

	log "INFO" "Rsyslog nginx conf has been successfully configured on you system."
}


# ---------------------------------------- 
# validate that nginx is installed properly 
# ---------------------------------------- 
function validate_nginx_compatibility {
	log "INFO" "Validating that nginx is installed, and log files are accessible"

	# validate that nginx is installed as service
	if [ ! -f /etc/init.d/$NGINX_SERVICE_NAME ]; then
		log "ERROR" "Could not identify nginx service"
		exit 1
	fi

	if [ ! -f $NGINX_ACCESS_LOG_PATH ]; then
		log "ERROR" "Could find nginx access log file"
		exit 1
	else
		log "INFO" "Detected nginx access log file: $NGINX_ACCESS_LOG_PATH"
	fi

	if [ ! -f $NGINX_ERORR_LOG_PATH ]; then
		log "ERROR" "Could not find nginx error log file"
		exit 1
	else
		log "INFO" "Detected nginx error log file: $NGINX_ERORR_LOG_PATH"
	fi

	log "INFO" "Computing total size for nginx log files..."
	sum_files_size ${NGINX_ERORR_LOG_PATH} ${NGINX_ACCESS_LOG_PATH}
	file_size=$?
	
	log "INFO" "Nginx logs total size: $file_size"

	if [ $file_size -eq 0 ]; then
		log "WARN" "There are no recent logs from nginx, so there won't be any sent to logz.io."
		log "WARN" "You can generate some logs by visiting a page on your web server."
		exit 1
	fi

	log "INFO" "Nginx is installed, and log files are accessible with total size of $file_size"
}


# ----------------------------------------
# write the nginx rsyslog conf file
# ----------------------------------------
function write_nginx_conf {
	log "INFO" "Write the nginx rsyslog conf file: $RSYSLOG_NGINX_FILENAME"

	# location of logzio rsyslog template file
	local rsyslog_tmplate=$LOGZ_CONF_DIR/${RSYSLOG_NGINX_FILENAME}

	log "DEBUG" "Log conf file template path: ${rsyslog_tmplate}"

	execute sed -i "s|USER_TOKEN|${USER_TOKEN}|g" ${rsyslog_tmplate}
	execute sed -i "s|RSYSLOG_SPOOL_DIR|${RSYSLOG_SPOOL_DIR}|g" ${rsyslog_tmplate}
	execute sed -i "s|NGINX_ACCESS_LOG_PATH|${NGINX_ACCESS_LOG_PATH}|g" ${rsyslog_tmplate}
	execute sed -i "s|NGINX_ERORR_LOG_PATH|${NGINX_ERORR_LOG_PATH}|g" ${rsyslog_tmplate}

	write_conf ${RSYSLOG_NGINX_FILENAME}

	service_restart

	log "INFO" "Nginx rsyslog conf file has been configured"
}


# ---------------------------------------- 
# get the script parameters
# ---------------------------------------- 

# if the script is been included in anther script, execution needs to be prevented
SHOULD_INVOKE=${1:-"true"}

if [[ $SHOULD_INVOKE == "true" ]]; then
	install_rsyslog_nginx_conf
fi
