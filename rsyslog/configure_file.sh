#!/bin/bash

# ---------------------------------------- 
# Setup dependencies
# ---------------------------------------- 
source $LOGZ_DIR/configure_linux.sh "false"


# ---------------------------------------- 
# Setup variables
# ---------------------------------------- 

# ---------------------------------------- 
# initiate rsyslog a custom linux conf installation
# and validate compatibility 
# ---------------------------------------- 
function install_rsyslog_linux_conf {
	
}



# ---------------------------------------- 
# get the script parameters
# ---------------------------------------- 

# if the script is been included in anther script, execution needs to be prevented
SHOULD_INVOKE=${1:-"true"}

if [[ $SHOULD_INVOKE == "true" ]]; then
	install_rsyslog_file_conf
fi
