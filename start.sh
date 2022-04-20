#!/bin/bash

# start rsyslog
echo 'Starting rsyslog'
# remove lingering pid file
rm -f /run/rsyslogd.pid
# start service
service rsyslog start

# start rspamd
echo 'Starting weewx'
${WEEWX_HOME}/bin/weewxd