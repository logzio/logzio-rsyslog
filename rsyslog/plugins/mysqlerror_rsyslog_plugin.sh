#!/bin/bash

TOKEN=$1
TYPE=$2
LOG_LINE=""
echo "TOKEN IS $TOKEN and TYPE IS $TYPE"
while read line
do

    regex='^([0-9][0-9][0-9][0-9][0-9][0-9]\s+?([0-9])*[0-9]:[0-9][0-9]:[0-9][0-9]|[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]\s+?([0-9])*[0-9]:[0-9][0-9]:[0-9][0-9]).*'
    
    echo "loop start $line"

    if [[ $LOG_LINE == "" ]]; then
        echo "loop first catch"
        LOG_LINE=$(echo $line)
   else
        echo "loop adding"

        LOG_LINE=$(echo $LOG_LINE LOGZIO_LF $line)
   fi

   if [[ $line =~ $regex ]]; then

         LOG_LINE=$(echo $line)
         echo "[$TOKEN][type=$TYPE]$LOG_LINE"
        echo "[$TOKEN][type=$TYPE]$LOG_LINE" | nc listener.logz.io 8010
    fi

    echo "loop end"

done < /dev/stdin