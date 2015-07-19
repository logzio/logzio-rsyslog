#!/bin/bash

# clear
rm -rf dist

# build
mkdir dist

tar -zcvf dist/logzio-rsyslog.tar.gz --exclude='rsyslog/.vagrant/' --exclude='rsyslog/Vagrantfile' --exclude='rsyslog/tests/' --exclude='rsyslog/.git*' rsyslog

exit 0