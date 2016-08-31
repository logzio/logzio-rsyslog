#!/bin/bash

# minimum version of rsyslog to enable logging to logzio
export MIN_RSYSLOG_VERSION=7.5.3

# ---------------------------------------- 
# Setup dependencies
# ---------------------------------------- 
source $LOGZ_DIR/configure_linux.sh


# ---------------------------------------- 
# Setup variables
# ---------------------------------------- 

# The name of the mysql service
MYSQL_SERVICE_NAME="mysql"

# The name of logzio syslog conf file
RSYSLOG_MYSQL_FILENAME="21-logzio-mysql.conf"
RSYSLOG_MYSQL_SLOW_FILENAME="21-logzio-mysql-slow.conf"
RSYSLOG_MYSQL_ERROR_FILENAME="21-logzio-mysql-error.conf"


# ---------------------------------------- 
# script arguments (override defaults)
# ---------------------------------------- 
while :; do
    case $1 in
		--errorlog ) shift
			MYSQL_ERORR_LOG_PATH=$(readlink -f "$1")

			if [ -f "$MYSQL_ERORR_LOG_PATH" ];then
				MYSQL_ERROR_LOG_FILE_NAME="${MYSQL_ERORR_LOG_PATH##*/}"
				log "INFO" "Monitoring file: $MYSQL_ERORR_LOG_PATH"
			else
				log "ERROR" "Cannot access $MYSQL_ERORR_LOG_PATH: No such file"
				exit 1
			fi
			;;
		--generallog ) shift
			MYSQL_LOG_PATH=$(readlink -f "$1")

			if [ -f "$MYSQL_LOG_PATH" ];then
				MYSQL_LOG_FILE_NAME="${MYSQL_LOG_PATH##*/}"
				log "INFO" "Monitoring file: $MYSQL_LOG_PATH"
			else
				log "ERROR" "Cannot access $MYSQL_LOG_PATH: No such file"
				exit 1
			fi
			;;
		--slowlog ) shift
			MYSQL_SLOW_LOG_PATH=$(readlink -f "$1")

			if [ -f "$MYSQL_SLOW_LOG_PATH" ];then
				MYSQL_SLOW_LOG_FILE_NAME="${MYSQL_SLOW_LOG_PATH##*/}"
				log "INFO" "Monitoring file: $MYSQL_SLOW_LOG_PATH"
			else
				log "ERROR" "Cannot access $MYSQL_SLOW_LOG_PATH: No such file"
				exit 1
			fi
			;;
		-p | --filepath ) shift
			MYSQL_LOGS_DIRECTORY=$(readlink -f "$1")

			if is_directory "$MYSQL_LOGS_DIRECTORY"; then
				MONITOR_DIRECTORY="true"
				log "INFO" "Directory to monitor: $MYSQL_LOGS_DIRECTORY"

			else
				log "ERROR" "Cannot access $MYSQL_LOGS_DIRECTORY: No such directory"
				exit 1
			fi
			;;
        --) # End of all options.
            shift
            break
            ;;
        *)  # Default case: If no more options then break out of the loop.
            break
    esac

    shift
done

function set_mysql_defaults {
	if [[ -z $MYSQL_LOGS_DIRECTORY ]]; then
		# The path to the mysql log folder
		MYSQL_LOGS_DIRECTORY="/var/log/$MYSQL_SERVICE_NAME"
	fi

	if [[ -z $MYSQL_LOG_FILE_NAME ]]; then
		# The name of mysql log file
		MYSQL_LOG_FILE_NAME="mysql.log"
		# The path of mysql log file
		MYSQL_LOG_PATH=$MYSQL_LOGS_DIRECTORY/$MYSQL_LOG_FILE_NAME
	fi

	if [[ -z $MYSQL_ERROR_LOG_FILE_NAME ]]; then
		# The name of mysql error log file
		MYSQL_ERROR_LOG_FILE_NAME="error.log"
		# The path to mysql error log file
		MYSQL_ERORR_LOG_PATH=$MYSQL_LOGS_DIRECTORY/$MYSQL_ERROR_LOG_FILE_NAME
	fi

	if [[ -z $MYSQL_SLOW_LOG_FILE_NAME ]]; then
		# The name of mysql slow log file
		MYSQL_SLOW_LOG_FILE_NAME="mysql-slow.log"
		# The path of mysql log file
		MYSQL_SLOW_LOG_PATH=$MYSQL_LOGS_DIRECTORY/$MYSQL_SLOW_LOG_FILE_NAME
	fi
}

# ---------------------------------------- 
# initiate rsyslog mysql conf installation
# and validate compatibility 
# ---------------------------------------- 
function install_rsyslog_mysql_conf {
	# copy plugins
	copy_plugins	

	# install_rsyslog_conf
	set_mysql_defaults

	log "INFO" "Install mysql rsyslog config"
	# validate mysql compatibility requirements are reached.
	validate_mysql_compatibility

	# create the rsyslog config file
	write_mysql_conf_files

	log "INFO" "Rsyslog mysql conf has been successfully configured on you system."
}

# ---------------------------------------- 
# validate that mysql is installed properly 
# ---------------------------------------- 
function validate_mysql_compatibility {
	log "INFO" "Validating that mysql is properly installed, and log files are accessible"
	local num_of_log_files=0
	if [ ! -f $MYSQL_LOG_PATH ]; then
		log "WARN" "Could find mysql access log file, please verify that mysql is properly installed on your system before you continue"
	else
		log "INFO" "Detected mysql log file: $MYSQL_LOG_PATH"
		num_of_log_files=$((num_of_log_files+1))
	fi

	if [ ! -f $MYSQL_SLOW_LOG_PATH ]; then
		log "WARN" "Could not find mysql slow log file, please verify that mysql is properly installed on your system before you continue"
	else
		log "INFO" "Detected mysql slow log file: $MYSQL_SLOW_LOG_PATH"
		num_of_log_files=$((num_of_log_files+1))
	fi

	if [ ! -f $MYSQL_ERORR_LOG_PATH ]; then
		log "WARN" "Could not find mysql error log file, please verify that mysql is properly installed on your system before you continue"
	else
		log "INFO" "Detected mysql error log file: $MYSQL_ERORR_LOG_PATH"
		num_of_log_files=$((num_of_log_files+1))
	fi

	if [[ num_of_log_files -eq 0 ]]; then
		log "ERROR" "No log file has been detected, please verify paths"
		exit 1
	fi

	log "INFO" "MYSQL is installed, and log files are accessible"
}


# ----------------------------------------
# write the mysql rsyslog conf file
# ----------------------------------------
function write_mysql_conf_files {
	if [ -f $MYSQL_LOG_PATH ]; then
		log "INFO" "Write the mysql rsyslog conf file: $RSYSLOG_MYSQL_FILENAME"

		write_mysql_conf $MYSQL_LOG_PATH $RSYSLOG_MYSQL_FILENAME

		# validate that logs are been sent
		validate_rsyslog_logzio_installation ${RSYSLOG_MYSQL_FILENAME}
	fi

	if [ -f $MYSQL_SLOW_LOG_PATH ]; then
		log "INFO" "Write the mysql rsyslog conf file: $RSYSLOG_MYSQL_SLOW_FILENAME"

		write_mysql_conf $MYSQL_SLOW_LOG_PATH $RSYSLOG_MYSQL_SLOW_FILENAME
		
		# validate that logs are been sent
		validate_rsyslog_logzio_installation ${RSYSLOG_MYSQL_SLOW_FILENAME}
	fi

	if [ -f $MYSQL_ERORR_LOG_PATH ]; then
		log "INFO" "Write the mysql rsyslog conf file: $RSYSLOG_MYSQL_ERROR_FILENAME"

		write_mysql_conf $MYSQL_ERORR_LOG_PATH $RSYSLOG_MYSQL_ERROR_FILENAME
		
		# validate that logs are been sent
		validate_rsyslog_logzio_installation ${RSYSLOG_MYSQL_ERROR_FILENAME}
	fi

	service_restart

	log "INFO" "MYSQL rsyslog conf files has been configured"
}

# ----------------------------------------
# write the mysql rsyslog conf file
# ----------------------------------------
function write_mysql_conf {
	# monitor file
	local mysql_log_path=$1
	# template name
	local rsyslog_tmplate_name=$2
	# location of logzio rsyslog template file
	local rsyslog_tmplate_path=$LOGZ_CONF_DIR/${rsyslog_tmplate_name}

	log "DEBUG" "Log conf file template path: ${rsyslog_tmplate_path}"

	execute sed -i "s|USER_TOKEN|${USER_TOKEN}|g" ${rsyslog_tmplate_path}
	execute sed -i "s|LISTENER_HOST|${LISTENER_HOST}|g" ${rsyslog_tmplate_path}
	execute sed -i "s|RSYSLOG_SPOOL_DIR|${RSYSLOG_SPOOL_DIR}|g" ${rsyslog_tmplate_path}
	execute sed -i "s|PATH_TO_FILE|${mysql_log_path}|g" ${rsyslog_tmplate_path}

	write_conf ${rsyslog_tmplate_name}
}



# ---------------------------------------- 
# start
# ---------------------------------------- 
install_rsyslog_mysql_conf