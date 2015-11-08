#!/bin/bash


# Log levels. Allowed values [1(DEBUG),2(INFO),3(WARN),4(ERROR)]
declare -A LOG_LEVELS &>/dev/null
LOG_LEVELS[DEBUG]=1
LOG_LEVELS[INFO]=2
LOG_LEVELS[WARN]=3
LOG_LEVELS[ERROR]=4

# ---------------------------------------- 
# debug logs to console on a log level
# ---------------------------------------- 
function log {
	if [ -z "$LOG_LEVELS" ]; then
		echo "[$1] ${*:2}"
		return 0
	fi

	local current_level=${LOG_LEVELS[$1]}
	
	if [[ "${current_level}" -ge "${LOG_LEVEL}" ]]; then
		echo "[$1] ${*:2}"
	fi
}


# ---------------------------------------- 
# accept a command as an argument, on error
# exit with status code on error
# ---------------------------------------- 
function execute {
	log "DEBUG" "Running command: $@"
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        log "ERROR" "Occurred while executing: $@" >&2
        exit $status
    fi
}


# ---------------------------------------- 
# validate that the user has root privileges
# ---------------------------------------- 
function is_root {
	#This script needs to be run as a sudo user
	if [[ $EUID -ne 0 ]]; then
	   log "ERROR" "This script must be run as root."
	   exit 1
	fi
}

# ---------------------------------------- 
# check if the linux dist is ubuntu
# ---------------------------------------- 
function is_ubuntu {
	if [[ "$LINUX_DIST" == *"Ubuntu"* ]]; then
		return 0
	else
		return 1
	fi
}

# ---------------------------------------- 
# check if the dist is yum_based
# ---------------------------------------- 
function is_yum_based {
	YUM_BASED=$(command -v yum)
	
	if [ "$YUM_BASED" != "" ]; then
		return 0
	fi
	return 1
}

# ---------------------------------------- 
# check if the dist is apt_based
# ---------------------------------------- 
function is_apt_based {
	APT_GET_BASED=$(command -v apt-get)
	
	if [ "$APT_GET_BASED" != "" ]; then
		return 0
	fi

	return 1
}

# ---------------------------------------- 
# check if the pckages are installed
# ---------------------------------------- 
function is_installed {
	if is_yum_based; then
		if yum list installed "$@" >/dev/null 2>&1; then
			return 0
		else
			return 1
		fi
	elif is_apt_based; then
		dpkg-query -l "$@" >/dev/null 2>&1
		return $?
	fi
}

function would_you_like_to_continue {
	if [ "$INTERACTIVE_MODE" == "true" ]; then
		while true; do
			read -p "[INFO] Would you like to continue? [yes|no]" yn
			case $yn in
				[Yy]* )
				break;;
				[Nn]* )
					return 1
				;;
				* ) echo "[INFO] Please answer yes or no.";;
			esac
		done
	else 
		continue=$1
		
		if [[ -z $continue ]]; then
			# set default return value to "please continue"
			continue=0
		fi

		return $continue
	fi

	return 0
}

# ---------------------------------------- 
# check if the os is supported 
# validate the user os, if the os is not supported, the script will exit with error, 
# for untested os the user will be asked if he wish to continue.
# ---------------------------------------- 
function is_os_supported {
	log "INFO" "validating operation system compatibility"

	get_os
	
	local dist=$(echo $LINUX_DIST | tr "[:upper:]" "[:lower:]")
	
	case "$dist" in
		*"ubuntu"* )
		log "INFO" "Operating system is Ubuntu."
		;;
		*"redhat"* )
		log "INFO" "Operating system is Red Hat."
		;;
		*"centos"* )
		log "INFO" "Operating system is CentOS."
		;;
		*"debian"* )
		log "INFO" "Operating system is Debian."
		;;
		*"amazon"* )
		log "INFO" "Operating system is Amazon AMI."
		;;
		*"darwin"* )
		#if the OS is mac then exit
		log "ERROR" "Darwin or Mac OSX are not currently supported."
		exit 1
		;;
		* )
		log "WARN" "The linux distribution $LINUX_DIST has not been previously tested with Logz.io."
		if [ "$INTERACTIVE_MODE" == "true" ]; then
			while true; do
				read -p "Would you like to continue anyway? [yes|no]" yn
				case $yn in
					[Yy]* )
					break;;
					[Nn]* )
					exit 1	
					;;
					* ) echo "Please answer yes or no.";;
				esac
			done
		fi
		;;
	esac
}


# ---------------------------------------- 
# get linux operation system distribution 
# ----------------------------------------
function get_os {
	# Determine OS platform
	UNAME=$(uname | tr "[:upper:]" "[:lower:]")
	# If Linux, try to determine specific distribution
	if [ "$UNAME" == "linux" ]; then
		# If available, use LSB to identify distribution
		if [ -f /etc/lsb-release -o -d /etc/lsb-release.d ]; then
			LINUX_DIST=$(lsb_release -i | cut -d: -f2 | sed s/'^\t'//)
		# If system-release is available, then try to identify the name
		elif [ -f /etc/system-release ]; then
			LINUX_DIST=$(cat /etc/system-release  | cut -f 1 -d  " ")
		# Otherwise, use release info file
		else
			LINUX_DIST=$(ls -d /etc/[A-Za-z]*[_-][rv]e[lr]* | grep -v "lsb" | cut -d'/' -f3 | cut -d'-' -f1 | cut -d'_' -f1)
		fi
	fi

	# For everything else (or if above failed), just use generic identifier
	if [ "$LINUX_DIST" == "" ]; then
		LINUX_DIST=$(uname)
	fi
}


# ----------------------------------------
# write the rsyslog conf file
# ----------------------------------------
function write_conf {
	# name of logzio rsyslog conf file
	local rsyslog_filename=${1}
	
	# location of logzio rsyslog conf file
	local rsyslog_conf_file=$RSYSLOG_ETC_DIR/${rsyslog_filename}
	
	# name and location of logzio syslog backup file
	local rsyslog_conf_file_backup=$rsyslog_conf_file.bk
	
	# location of logzio rsyslog template file
	local rsyslog_tmplate=$LOGZ_CONF_DIR/${rsyslog_filename}

	log "INFO" "Checking if rsyslog conf file ${rsyslog_filename} exist."
	
	# check if the file is already exist ?
	if [ -f "${rsyslog_conf_file}" ]; then
		log "INFO" "The rsyslog file: ${rsyslog_filename} already exist.."
		log "INFO" "Backing up current conf file at: $rsyslog_conf_file_backup"
		execute mv -f ${rsyslog_conf_file} $rsyslog_conf_file_backup
	fi

	log "INFO" "Adding rsyslog config at: ${rsyslog_conf_file}"
	execute cp -f ${rsyslog_tmplate} ${rsyslog_conf_file}

	execute chmod o+w ${rsyslog_conf_file}
}


# ----------------------------------------
# append content to the rsyslog conf file
# ----------------------------------------
function append_to_conf {
	# name of logzio rsyslog conf file
	local rsyslog_filename=${1}

	# location of logzio rsyslog conf file
	local rsyslog_conf_file=$RSYSLOG_ETC_DIR/${rsyslog_filename}
	
	# location of logzio rsyslog template file
	local rsyslog_tmplate=$LOGZ_CONF_DIR/${rsyslog_filename}

	log "INFO" "Appending rsyslog config to: ${rsyslog_filename}"
	execute cat ${rsyslog_tmplate} >> ${rsyslog_conf_file}

	execute chmod o+w ${rsyslog_conf_file}
}


# ---------------------------------------- 
# deletes/refresh the state file
# ---------------------------------------- 
function refresh_state_file {
	local file_name=$1
	service $RSYSLOG_SERVICE_NAME stop
	sudo rm -f $RSYSLOG_SPOOL_DIR/$file_name
	service $RSYSLOG_SERVICE_NAME start
}


# ---------------------------------------- 
# sum the size of a list of files
# ---------------------------------------- 
function sum_files_size {
	file_size=0

	for file in $@; do
		_file_size=$(wc -c "$file" | cut -f 1 -d ' ')

		log "DEBUG" "File size for: ${file} is ${_file_size}"
		file_size=$((file_size+_file_size))
	done

	log "DEBUG" "Sum of files size: ${file_size}"
	return $file_size
}

# ---------------------------------------- 
# check if a path is a dirctory
# ---------------------------------------- 
function is_directory {
	local path=$1

	if [[ -d $path ]]; then
		return 0
	fi

	return 1
}

# ---------------------------------------- 
# check if a path is a file
# ---------------------------------------- 
function is_file {
	local path=$1

	if [[ -f $path ]]; then
		return 0
	fi

	return 1	
}

# ---------------------------------------- 
# check if is a file and contains text
# ---------------------------------------- 
function is_text_file {
	local path=$1

	if is_file $path; then
		
		local file_desc=$(file $path)
		#checking if it is a text file
		file_desc=$(echo $file_desc | tr "[:upper:]" "[:lower:]")

		if [[ $file_desc == *text* ]]; then
			return 0
		fi

	fi

	return 1	
}

# ---------------------------------------- 
# validate proper logfile permission read 
# by a given os distribution
# ---------------------------------------- 
function validate_logfile_read_permission {	
	log "INFO" "Validate that the file has a proper read permission..."
	local logfile=$1

	# resolve os
	get_os
	
	local dist=$(echo $LINUX_DIST | tr "[:upper:]" "[:lower:]")
	# ignore redhat and centos, as they will by ok with (000)permissions
	case "$dist" in
		*"redhat"* )
		;;
		*"centos"* )
		;;
		* )
			local group=$(ls -al $logfile | awk '{print $4}')
			local permissions=$(ls -l $logfile)
			# checking if the file has read permission for others or it belong to group 'adm'
			local read_permission_others=${permissions:7:1}
			if [[ $read_permission_others != r ]] || [[ $group == 'adm' ]]; then 
				log "ERROR" "file $logfile does not have proper read permissions!"
				return 1
			fi
		;;
	esac

	log "INFO" "File permission validated: $logfile"
	return 0
}

# ---------------------------------------- 
# Ensure that logs are been sent to logz.io 
# listener server, and that they are been processed 
# ---------------------------------------- 
function validate_rsyslog_logzio_installation {
	if [[ ! -f $RSYSLOG_ETC_DIR/$1 ]]; then
		log "ERROR" "Failed to find $1 at $RSYSLOG_ETC_DIR, something went wrong, Please address the manual installation at:"
		log "ERROR" "https://app.logz.io/#/dashboard/data-sources/"

		exit 1
	fi
}

# ---------------------------------------- 
# restart rsyslog
# ---------------------------------------- 
function service_restart {
	log "INFO" "Restarting the $RSYSLOG_SERVICE_NAME service."
	service $RSYSLOG_SERVICE_NAME restart
	if [ $? -ne 0 ]; then
		log "WARNING" "$RSYSLOG_SERVICE_NAME did not restart gracefully. Please try to restart $RSYSLOG_SERVICE_NAME manually."
	fi
}


# ---------------------------------------- 
# copy logzio rsyslog plugins
# ---------------------------------------- 
function copy_plugins {
	log "DEBUG" "copy plugins ..."
	mkdir -p /opt/logzio
	cp -ar ${LOGZ_DIR}/plugins /opt/logzio
	chmod +x -R /opt/logzio/plugins
}


# ---------------------------------------- 
# cleanup: delete logzio dir
# ---------------------------------------- 
function cleanup {
	log "DEBUG" "Cleanup: delete logzio dir"
	rm -rf $LOGZ_DIR
}


# ---------------------------------------- 
# version compare 
# ----------------------------------------
function vercomp {
    if [[ $1 == $2 ]]
    then
    	# version are equal
        return 0
    fi
    local IFS=.
    local i ver1=($1) ver2=($2)
    # fill empty fields in ver1 with zeros
    for ((i=${#ver1[@]}; i<${#ver2[@]}; i++))
    do
        ver1[i]=0
    done
    for ((i=0; i<${#ver1[@]}; i++))
    do
        if [[ -z ${ver2[i]} ]]
        then
            # fill empty fields in ver2 with zeros
            ver2[i]=0
        fi
        if ((10#${ver1[i]} > 10#${ver2[i]}))
        then
        	# v1 is grater then v2
            return 1
        fi
        if ((10#${ver1[i]} < 10#${ver2[i]}))
        then
        	# v1 is less then v2
            return 2
        fi
    done
    return 0
}
