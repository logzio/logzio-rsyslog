#!/bin/bash

# ---------------------------------------- 
# Setup dependencies
# ---------------------------------------- 
source $LOGZ_DIR/configure_linux.sh


# ---------------------------------------- 
# File monitor script usage info
# ---------------------------------------- 
function usage-file {
	echo
	echo "Description:"
    echo "Configure Rsyslog to monitor a file or directory, and to forward logs to logz.io"
    echo "Version: $SCRIPT_VERSION" 
    echo
    echo "Usage:"
	echo "$(basename $0) -a auth_token -t file -tag filetag -p filepath [-q suppress prompts] [-v verbose] [-h for help]"
	echo
	echo

    exit $1
}


# ---------------------------------------- 
# Setup User variables
# ---------------------------------------- 

FILE_PATH=""
FILE_TAG=""


# ---------------------------------------- 
# script arguments
# ---------------------------------------- 
while :; do
    case $1 in
		-p | --filepath ) shift
			FILE_PATH=$(readlink -f "$1")

			if [ -f "$FILE_PATH" ];then
				log "INFO" "Monitoring file: $FILE_PATH"

			elif is_directory "$FILE_PATH"; then
				MONITOR_DIRECTORY="true"
				log "INFO" "Directory to monitor: $FILE_PATH"

			else
				log "ERROR" "Cannot access $FILE_PATH: No such file or directory"
				exit 1
			fi
			;;
		-tag| --filetag ) shift
			FILE_TAG=$1
			echo "Setting file tag name to: $FILE_TAG"
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


# ---------------------------------------- 
# Setup variables
# ---------------------------------------- 
RSYSLOG_FILE_FILENAME="21-logzio-${CODEC_TYPE}-file-${FILE_TAG}.conf"

if [[ -z $FILE_TAG ]] || [[ -z $FILE_PATH ]]; then
	usage-file 1
fi


# ---------------------------------------- 
# initiate rsyslog a custom linux conf installation, for single
# file and directories, and validate compatibility 
# ---------------------------------------- 
function install_rsyslog_file_conf {
	# initiate rsyslog conf installation and validate compatibility 
	#install_rsyslog_conf

	log "INFO" "Configure rsyslog for $RSYSLOG_FILE_FILENAME"

	# validate that the file name dose not contain spaces, and it exist
	validate_monitor_path

	if is_directory $FILE_PATH; then
		monitor_directory
	else
		monitor_file $FILE_PATH "false"
	fi

	# validate that logs are been sent
	validate_rsyslog_logzio_installation ${RSYSLOG_FILE_FILENAME}

	service_restart

	log "INFO" "Rsyslog $RSYSLOG_FILE_FILENAME conf has been successfully configured on you system."
}



# ---------------------------------------- 
# validate that the file name dose not contain spaces
# and that it exist under the specified path
# ---------------------------------------- 
function validate_monitor_path {
	pattern=" |'"
	if [[ $FILE_PATH =~ $pattern ]]; then
		log "ERROR" "White spaces are not allowed, File path: $FILE_PATH"
		exit 1
	fi
}


# ---------------------------------------- 
# validate that file exist, and it's a txt file 
# whit a proper read permission
# ---------------------------------------- 
function validate_file {
	local monitored_file=$1
	
	if ! is_file $monitored_file; then
		log "ERROR" "Cannot find file: $monitored_file."
		log "ERROR" "Please validate that you specify the correct file path."
		return 1
	fi

	if ! validate_logfile_read_permission; then
		log "WARN" "Please validate that you give the log file read permission for 'others' or attached to the 'adm' group."
	fi

	sum_files_size $monitored_file
	file_size=$?
	
	log "INFO" "The total file size of file $monitored_file is: $file_size"

	if [ $file_size -eq 0 ]; then
		log "WARN" "It seems that there are no recent logs in $monitored_file, so there won't be any sent to logz.io."
		return 1
	fi

	if ! is_text_file $monitored_file; then
		log "ERROR" "The file: $monitored_file is not a TEXT file..."
		log "ERROR" "Please validate that you specify the correct file path."
		return 1
	fi
}

function monitor_directory {
	log "INFO" "INFO" "Configuring all files under the directory: $FILE_PATH"
	log "INFO" "Listing files:"
	ls -1 $FILE_PATH

	local append="false"
	
	for file in $(find $FILE_PATH -type f -name '*')
	do	
		monitor_file $file $append

		append="true"

		if [[ $? -ne 0 ]]; then
			log "INFO" "INFO" "File $file, is not valid, skipping ..."
		fi

	done
}

function monitor_file {
	validate_file $1

	local is_valid=$?

	if [[ $is_valid -ne 0 ]]; then
		return $is_valid
	fi

	write_file_conf $1 $2
}

# ----------------------------------------
# write the rsyslog conf file
# ----------------------------------------
function write_file_conf {
	local append=$2
	local monitored_file_path=$1
	local monitored_file_normilized_name=$(echo ${1##*/} | tr . - | tr _ -);
	local monitored_file_tag=${monitored_file_normilized_name}-$FILE_TAG
	local monitored_state_file=stat-logzio-$(echo -n "$monitored_file_normilized_name" | md5sum | tr -d ' ')$FILE_TAG

	# location of logzio rsyslog template file
	local rsyslog_tmplate=$LOGZ_CONF_DIR/21-logzio-${CODEC_TYPE}-file.conf
	local tmp_rsyslog_tmplate=$LOGZ_CONF_DIR/${RSYSLOG_FILE_FILENAME}
	
	log "INFO" "Write the rsyslog conf file: $RSYSLOG_FILE_FILENAME"
	log "INFO" "Monitored file path: $monitored_file"
	log "INFO" "Monitored file tag name: $monitored_file_tag"
	log "INFO" "Monitored state file name: $monitored_state_file"
	log "DEBUG" "Rsyslog conf file template path: ${rsyslog_tmplate}"

	execute cp -f $rsyslog_tmplate $tmp_rsyslog_tmplate

	execute sed -i "s|USER_TOKEN|${USER_TOKEN}|g" ${tmp_rsyslog_tmplate}
	execute sed -i "s|LISTENER_HOST|${LISTENER_HOST}|g" ${tmp_rsyslog_tmplate}
	execute sed -i "s|RSYSLOG_SPOOL_DIR|${RSYSLOG_SPOOL_DIR}|g" ${tmp_rsyslog_tmplate}
	execute sed -i "s|PATH_TO_FILE|${monitored_file_path}|g" ${tmp_rsyslog_tmplate}
	execute sed -i "s|FILE_TAG_NAME|${monitored_file_tag}|g" ${tmp_rsyslog_tmplate}
	execute sed -i "s|TAG_NAME|${FILE_TAG}|g" ${tmp_rsyslog_tmplate}
	execute sed -i "s|STATE_FILE_NAME|${monitored_state_file}|g" ${tmp_rsyslog_tmplate}

	if [[ "$append" == "true" ]]; then
		append_to_conf ${RSYSLOG_FILE_FILENAME} 
	else
		write_conf ${RSYSLOG_FILE_FILENAME} 
	fi

	execute rm -f $tmp_rsyslog_tmplate

	log "INFO" "Rsyslog conf file has been added"
}


# ---------------------------------------- 
# start
# ---------------------------------------- 
install_rsyslog_file_conf
