#!/bin/bash

TOKEN=$1
TYPE=$2
LOG_LINE=""

while read line
do

  regex='User@Host:'
  ignore='Time: [0-9][0-9][0-9][0-9][0-9][0-9]\s+?([0-9])*[0-9]:[0-9][0-9]:[0-9][0-9]'
  if [[ $line =~ $ignore ]]; then
        echo $line > /dev/null
  elif [[ $line =~ $regex ]] && [[ $LOG_LINE != "" ]]; then
        echo "[$TOKEN][type=$TYPE]$LOG_LINE" | nc $LISTENER_HOST 8010
        LOG_LINE=$(echo $line)
  elif [[ $LOG_LINE == "" ]]; then
        LOG_LINE=$(echo $line)
  else
        LOG_LINE=$(echo $LOG_LINE LOGZIO_LF $line)
  fi

done < /dev/stdin