#!/bin/bash

# ---------------------------------------- 
# Setup dependencies
# ---------------------------------------- 
source $LOGZ_DIR/configure_linux.sh "false"



# ---------------------------------------- 
# Setup variables
# ---------------------------------------- 

# The name of the apache service
APACHE_SERVICE_NAME=""

# The path to the apache log folder
APACHE_LOGS_DIRECTORY=""

# The name of apache access log file
APACHE_ACCESS_LOG_FILE_NAME=""

# The name of apache error log file
APACHE_ERROR_LOG_FILE_NAME=""

# The name of logzio syslog conf file
RSYSLOG_APACHE_FILENAME="21-logzio-apache.conf"


# ---------------------------------------- 
# initiate rsyslog apache conf installation
# and validate compatibility 
# ---------------------------------------- 
function install_rsyslog_apache_conf {
	# initiate rsyslog conf installation and validate compatibility 
	install_rsyslog_conf

	log "INFO" "Install apache rsyslog config"

	# validate apache compatibility requirements are reached.
	validate_apache_compatibility

	# create the rsyslog config file
	write_apache_conf

	# validate that logs are been sent
	validate_rsyslog_logzio_installation ${RSYSLOG_APACHE_FILENAME}

	log "INFO" "Rsyslog apache2 conf has been successfully configured on you system."
}


# ---------------------------------------- 
# validate that apache is installed properly 
# ----------------------------------------
function validate_apache_compatibility {
	log "INFO" "Validating that apache is installed, and log files are accessible"

	if is_yam_based; then
		APACHE_SERVICE_NAME="httpd"
		APACHE_ACCESS_LOG_FILE_NAME="access_log"
		APACHE_ERROR_LOG_FILE_NAME="error_log"
	
	elif is_apt_based; then
		APACHE_SERVICE_NAME="apache2"
		APACHE_ACCESS_LOG_FILE_NAME="access.log"
		APACHE_ERROR_LOG_FILE_NAME="error.log"
	fi

	# validate that apache is installed as service
	if [ ! -f /etc/init.d/$APACHE_SERVICE_NAME ]; then
		log "ERROR" "Could not identify apache service, please verify that apache is properly installed on your system before you continue."
		exit 1
	fi

	APACHE_LOGS_DIRECTORY=/var/log/$APACHE_SERVICE_NAME
	APACHE_ERORR_LOG_PATH=$APACHE_LOGS_DIRECTORY/$APACHE_ERROR_LOG_FILE_NAME
	APACHE_ACCESS_LOG_PATH=$APACHE_LOGS_DIRECTORY/$APACHE_ACCESS_LOG_FILE_NAME

	if [ ! -f $APACHE_ACCESS_LOG_PATH ]; then
		log "ERROR" "Could find apache access log file, please verify that apache is properly installed on your system before you continue."
		exit 1
	else
		log "INFO" "Detected apache access log file: $APACHE_ACCESS_LOG_PATH"
	fi

	if [ ! -f $APACHE_ERORR_LOG_PATH ]; then
		log "ERROR" "Could not find apache error log file, please verify that apache is properly installed on your system before you continue."
		exit 1
	else
		log "INFO" "Detected apache error log file: $APACHE_ERORR_LOG_PATH"
	fi

	log "INFO" "Computing total size for apache log files..."

	sum_files_size ${APACHE_ACCESS_LOG_PATH} ${APACHE_ERORR_LOG_PATH}
	file_size=$?

	if [ $file_size -eq 0 ]; then
		log "WARN" "There are no recent logs from apache, so there won't be any sent to logz.io."
		log "WARN" "You can generate some logs by visiting a page on your web server."
		exit 1
	fi

	log "INFO" "Apache logs total size: $file_size"

	# validate required apache version
	local apache_version=`$APACHE_SERVICE_NAME -v | grep version | awk '{print $3}' | tr -d "Apache/" | tr -d ' '`
	local apache_major_version=${apache_version%%.*}
 	
 	log "INFO" "Detected apache version: $apache_version"

	if [[ ($apache_major_version -ne 2 ) ]]; then
		log "ERROR" "Apache version 2.* is required."
		exit 1
	fi

	log "INFO" "Apache (${apache_version}) is installed, and log files are accessible with total size of $file_size"

}


function write_apache_conf {
	# location of logzio rsyslog template file
	local rsyslog_tmplate=$LOGZ_CONF_DIR/${RSYSLOG_APACHE_FILENAME}

	log "DEBUG" "Log conf file template path: ${rsyslog_tmplate}"

	execute sed -i "s|USER_TOKEN|${USER_TOKEN}|g" ${rsyslog_tmplate}
	execute sed -i "s|RSYSLOG_SPOOL_DIR|${RSYSLOG_SPOOL_DIR}|g" ${rsyslog_tmplate}
	execute sed -i "s|APACHE_ACCESS_LOG_PATH|${APACHE_ACCESS_LOG_PATH}|g" ${rsyslog_tmplate}
	execute sed -i "s|APACHE_ERORR_LOG_PATH|${APACHE_ERORR_LOG_PATH}|g" ${rsyslog_tmplate}

	write_conf ${RSYSLOG_APACHE_FILENAME}

	service_restart
}


# ---------------------------------------- 
# get the script parameters
# ---------------------------------------- 

# if the script is been included in anther script, execution needs to be prevented
SHOULD_INVOKE=${1:-"true"}

if [[ $SHOULD_INVOKE == "true" ]]; then
	install_rsyslog_apache_conf
fi
