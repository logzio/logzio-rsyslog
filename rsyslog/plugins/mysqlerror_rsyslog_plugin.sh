#!/bin/bash

TOKEN=$1
TYPE=$2
LOG_LINE=""

while read line
do

    regex='^([0-9][0-9][0-9][0-9][0-9][0-9]\s+?([0-9])*[0-9]:[0-9][0-9]:[0-9][0-9]|[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\s+?([0-9])*[0-9]:[0-9][0-9]:[0-9][0-9]).*'
    
    if [[ $LOG_LINE == "" ]]; then
        LOG_LINE=$(echo $line)
   else
        LOG_LINE=$(echo $LOG_LINE LOGZIO_LF $line)
   fi

   if [[ $line =~ $regex ]]; then

        LOG_LINE=$(echo $line) 
        echo "[$TOKEN][type=$TYPE]$LOG_LINE" | nc $LISTENER_HOST 8010
    fi

done < /dev/stdin