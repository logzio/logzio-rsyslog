#!/bin/bash

function fresh_vagrent {
	execute_cmd vagrant destroy -f
	execute_cmd vagrant up
}

function run_logz {
	vagrant ssh -c "sudo /vagrant/install.sh --quite -a jMeylBTKkTxRnYeZfcbVmfRjnLBicggU -t $1"
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

