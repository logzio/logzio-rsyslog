#!/bin/bash

# ---------------------------------------- 
# Setup dependencies
# ---------------------------------------- 
source $LOGZ_DIR/configure_utils.sh


# ---------------------------------------- 
# Setup variables
# ---------------------------------------- 

# name of logzio syslog conf file
RSYSLOG_LINUX_FILENAME="22-logzio-linux.conf"
	
# directory location for syslog
RSYSLOG_ETC_DIR=/etc/rsyslog.d

# syslog directory
RSYSLOG_SPOOL_DIR=/var/spool/rsyslog

# rsyslog service name
RSYSLOG_SERVICE_NAME=rsyslog

# minimum version of rsyslog to enable logging to logzio
MIN_RSYSLOG_VERSION=5.8.0

# this variable will hold the users syslog version
CURRENT_RSYSLOG_VERSION=

# the conf file relevant to the rsyslog version number 
LOGZ_CONF_DIR=${LOGZ_DIR}/confs/${MIN_RSYSLOG_VERSION}

# the name of the linux distribution
LINUX_DIST=

# hostname for logz.io endpoint
LISTENER_HOST=listener.logz.io

# port for logz.io endpoint
LISTENER_PORT=5000


# ---------------------------------------- 
# initiate rsyslog conf installation
# and validate compatibility 
# ---------------------------------------- 
function install_rsyslog_conf {
	log "INFO" "Install linux rsyslog config"
	# create the rsyslog config file
	write_linux_conf

	# validate that logs are been sent
	validate_rsyslog_logzio_installation ${RSYSLOG_LINUX_FILENAME}

	log "INFO" "Rsyslog linux system conf has been successfully configured on you system."
}


# ----------------------------------------
# validate os compatibility and network 
# connectivity
# ----------------------------------------
function validate_os_compatibility {
	# validate the user os, if the os is not supported, the script will exit with error, for untested os the user will be prompt with a message 
	is_os_supported

	# validate that logz.io listener servers are accessible. On failure ask user to check network connectivity and exit
	validate_network_connectivity

	# validate that selinux service is not enforced. if it enforced, exit with error and ask the user to manually disable
	validate_selinux_not_enabled

	# ensure that the rsyslog spool directory created
	ensure_spool_dir
}


# ----------------------------------------
# validate network connectivity to logzio 
# listener servers
# ----------------------------------------
function validate_network_connectivity {
	log "INFO" "Checking if ${LISTENER_HOST} is reachable via ${LISTENER_PORT} port. This may take some time...."

	local is_nc_installed=`nc -h &>/dev/null && echo $?`

	if [[ $is_nc_installed -eq 0 ]]; then
		nc -z ${LISTENER_HOST} ${LISTENER_PORT}	
	else
		local is_telnet_installed=`telnet -n 2>&1 | grep "Usage" | wc -l`

		if [[ $is_telnet_installed -eq 0 ]]; then
			echo "-------------------------------------------"
			echo "INFO" "Running telnet in order to validate connectivity to loz.io servers"
			echo "INFO" "If connection is establish, a 'Connected to logz.io server', message will appear"
			echo "INFO" "and you will be asked to hit the keys: 'Ctrl' followed by ']'"
			echo "INFO" "when the telnet prompt appears hit 'q'"
			echo "-------------------------------------------"

			telnet ${LISTENER_HOST} ${LISTENER_PORT}
		else
			log "ERROR" "In order to validate connectivity to logz.io server, one of the following package [nc (netcat) | telnet] must be installed."
			log "ERROR" "Please install them before we continue"
        	
        	would_you_like_to_continue

        	res=$?
			if [ $res -eq 1 ]; then
				exit 1
			fi
		fi
	fi

	local status=$?
    if [ $status -ne 0 ]; then
        log "ERROR" "Host: '${LISTENER_HOST}' is not reachable via port '${LISTENER_PORT}'."
        log "ERROR" "Please check your network and firewall settings to the following ip's on port ${LISTENER_PORT}."
        nslookup ${LISTENER_HOST} | grep Address
        exit $status
    else
    	log "INFO" "Host: '${LISTENER_HOST}' is reachable via port '${LISTENER_PORT}'."
    fi
}


# ----------------------------------------
# check if SeLinux service is enforced
# ----------------------------------------
function validate_selinux_not_enabled {
	log "INFO" "Validate that selinux status is not enforced."
	
	is_se_installed=$(getenforce -ds 2>/dev/null)
	
	if [ $? -ne 0 ]; then
		log "INFO" "Selinux status is not enforced."
	elif [ $(sudo getenforce | grep "Enforcing" | wc -l) -gt 0 ]; then
		log "ERROR" "Selinux status is 'Enforcing'. Please disable it and start the rsyslog daemon manually."
		exit 1
	fi
}


# ----------------------------------------
# validate rsyslog is up and running
# and all compatibility requirements are net
# ----------------------------------------
function setup_rsyslog {
	log "INFO" "Running compatibility checks ..."
	# validate compatibility requirements are reached.
	validate_os_compatibility

	# validate if rsyslog is configured as service. if not, then exit
	validate_rsyslog_is_running

	# validate a minimum version of rsyslog, exit if requirement aren't met 
	validate_rsyslog_min_version

	# validate that rsyslog has a valid configuration 
	validate_rsyslog_configuration

	log "INFO" "Rsyslog is compatible with the current installation"

}


# ----------------------------------------
# install rsyslog on the machine
# ----------------------------------------
function install_rsyslog {
	log "INFO" "Trying to install rsyslog .. "
	if is_yam_based; then
		execute yum -y install rsyslog > /dev/null
	elif is_apt_based; then
		execute apt-get -y install rsyslog > /dev/null
	else
		log "ERROR" "Failed to install rsyslog, in order to continue please install it manually. You can find installation instructions at: http://www.rsyslog.com/doc/v8-stable/installation/index.html"
	fi
}


# ----------------------------------------
# validate if rsyslog is configured as service
# ----------------------------------------
function validate_rsyslog_is_running {
	log "INFO" "Validate if rsyslog is configured as service"

	if [ ! -f /etc/init.d/$RSYSLOG_SERVICE_NAME ]; then
		log "ERROR" "$RSYSLOG_SERVICE_NAME is not present as service."
		log "INFO" "It seems that rsyslog is not installed on your system."
		log "INFO" "Starting to install rsyslog"

		# verify that the user would like to install
		would_you_like_to_continue

		# installing
		install_rsyslog
	fi

	log "INFO" "Ensuring that a rsyslog service is running"

	if [ $(ps -A | grep $RSYSLOG_SERVICE_NAME | wc -l) -eq 0 ]; then
		log "INFO" "$RSYSLOG_SERVICE_NAME is not running. Attempting to start service."
		execute sudo service $RSYSLOG_SERVICE_NAME start
	fi
	
	if [ $(ps -A | grep $RSYSLOG_SERVICE_NAME | wc -l) -gt 1 ]; then
		log "ERROR" "Multiple $RSYSLOG_SERVICE_NAME are running."
		exit 1
	fi
}


# ----------------------------------------
# validate rsyslog min version
# ----------------------------------------
function validate_rsyslog_min_version {
	log "INFO" "Validate that rsyslog version number is supported"

	CURRENT_RSYSLOG_VERSION=`sudo rsyslogd -v | grep rsyslogd | awk '{print $2}' | tr -d ","`

	vercomp $CURRENT_RSYSLOG_VERSION $MIN_RSYSLOG_VERSION
	
	res=$?
	if [ $res -eq 2 ]; then
		log "ERROR" "Minimum rsyslog version required ${MIN_RSYSLOG_VERSION}"
		exit 1
	fi
}


# ----------------------------------------
# validate that rsyslog has a valid configuration 
# ----------------------------------------
function validate_rsyslog_configuration {
	log "INFO" "Running checks on the current rsyslog configuration..."

	local has_errors="false"
	if [ $(rsyslogd -N1 -f /etc/rsyslog.conf 2>&1 | grep "error" | wc -l) -gt 0 ]; then
		has_errors="true"
	fi

	if [ $(rsyslogd -N1 -f /etc/rsyslog.conf 2>&1 | grep "please change syntax" | wc -l) -gt 0 ]; then
		has_errors="true"
	fi

	if [[ "$has_errors" == "true" ]]; then
		log "ERROR" "It seems the your /etc/rsyslog.conf, contain syntax errors."
		log "ERROR" "It's recommended that you will fix them before continuing !"
	
		would_you_like_to_continue

    	res=$?
		if [ $res -eq 1 ]; then
			exit 1
		fi
	fi

}

# ----------------------------------------
# write the linux rsyslog conf file
# ----------------------------------------
function write_linux_conf {
	# location of logzio rsyslog template file
	local rsyslog_tmplate=$LOGZ_CONF_DIR/${RSYSLOG_LINUX_FILENAME}

	log "DEBUG" "Log conf file template path: ${rsyslog_tmplate}"

	execute sed -i "s|USER_TOKEN|${USER_TOKEN}|g" ${rsyslog_tmplate}
	execute sed -i "s|RSYSLOG_SPOOL_DIR|${RSYSLOG_SPOOL_DIR}|g" ${rsyslog_tmplate}

	write_conf ${RSYSLOG_LINUX_FILENAME}

	service_restart
} 


# ---------------------------------------- 
# Ensure that the rsyslog spool directory
# is created and has the proper permissions 
# ---------------------------------------- 
function ensure_spool_dir {
	log "INFO" "Ensuring that the rsyslog spool directory is created and has the proper permissions"

	if [ ! -d "$RSYSLOG_SPOOL_DIR" ]; then
		log "INFO" "Creating directory: $RSYSLOG_SPOOL_DIR"
		execute sudo mkdir -v $RSYSLOG_SPOOL_DIR
	fi

	if [[ is_ubuntu -eq 0 ]]; then
		log "INFO" "Setting permission on the rsyslog in $RSYSLOG_SPOOL_DIR"
		execute sudo chown -R syslog:adm $RSYSLOG_SPOOL_DIR
	fi
}

# ---------------------------------------- 
# Let go ..
# ---------------------------------------- 

# validate that rsyslog is installed and running as service.
setup_rsyslog

# ---------------------------------------- 
# get the script parameters
# ---------------------------------------- 

# if the script is been included in anther script, execution needs to be prevented
SHOULD_INVOKE=${1:-"true"}

if [[ $SHOULD_INVOKE == "true" ]]; then
	install_rsyslog_conf
fi


