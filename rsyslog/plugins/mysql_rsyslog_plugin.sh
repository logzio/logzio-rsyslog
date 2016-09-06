#!/bin/bash

TOKEN=$1
TYPE=$2
LOG_LINE=""

while read line
do

  regex='[0-9][0-9][0-9][0-9][0-9][0-9]\s+?([0-9])*[0-9]:[0-9][0-9]:[0-9][0-9]'
  quit_statement=$(echo $line | grep Quit | wc -l)

  if [[ $line =~ $regex ]] && [[ $LOG_LINE != "" ]] && [[ $quit_statement -eq 0 ]]; then
        echo "[$TOKEN][type=$TYPE]$LOG_LINE" | nc $LISTENER_HOST 8010
        LOG_LINE=$(echo $line)
  elif [[ $LOG_LINE == "" ]]; then
        LOG_LINE=$(echo $line)
  else
        LOG_LINE=$(echo $LOG_LINE LOGZIO_LF $line)
  fi

done < /dev/stdin