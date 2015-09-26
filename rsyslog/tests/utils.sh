#!/bin/bash

function fresh_vagrent {
	execute_cmd vagrant destroy -f
	execute_cmd vagrant up
    local branch=`git rev-parse --abbrev-ref HEAD`
    execute_cmd vagrant ssh -c "curl -sLO https://github.com/logzio/logzio-rsyslog/raw/${branch}/dist/logzio-rsyslog.tar.gz && tar xzf logzio-rsyslog.tar.gz"
}

function run_logz {
    vagrant ssh -c "sudo /home/vagrant/rsyslog/install.sh -a NlwmHZamKoxOydJaPdoOxZOQqFHIpOaA $@"
}

function execute_cmd {
	echo "DEBUG" "Running command: $@"
    "$@"
    local status=$?
    if [ $status -ne 0 ]; then
        echo "ERROR" "Occurred while executing: $@" >&2
        exit $status
    fi
}

function execute_success_test {
	echo "------------------------------------------------------------" 
	echo "DEBUG" "Running TEST: $@   EXPECTED RESULT: OK"
	echo "------------------------------------------------------------" 
    "$@"
    local status=$?


    if [ $status -ne 0 ]; then
		echo "------------------------------------------------------------ ): " 
        echo "ERROR" "Failed to run test: $@ !!! " >&2
		echo "------------------------------------------------------------ ): " 
        exit $status
    else
		echo "------------------------------------------------------------ :) " 
    	echo "SUCCESS" "test: $@ complete !!! "
		echo "------------------------------------------------------------ :) " 
        
    fi
}

function execute_fail_test {
	echo "------------------------------------------------------------" 
	echo "DEBUG" "Running TEST: $@   EXPECTED RESULT: FAIL" 
	echo "------------------------------------------------------------" 
    "$@"
    local status=$?


    if [ $status -eq 0 ]; then
		echo "------------------------------------------------------------ ): " 
        echo "ERROR" "Failed to run test: $@ !!! " >&2
		echo "------------------------------------------------------------ ): " 
        exit $status
    else
		echo "------------------------------------------------------------ :) " 
    	echo "SUCCESS" "test: $@ complete !!! "
		echo "------------------------------------------------------------ :) " 
        
    fi
}

