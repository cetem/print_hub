#!/bin/bash

# Run as root

COMMON_USER=user
SCRIPTS_DIR=/home/$COMMON_USER/scripts
CUPS_DIR=/var/log/cups
TODAY=`date -u '+%Y'-'%m'-'%d'`
ZIPED_LOGS=/tmp/cups-logs-$TODAY.tar.gz

tar -zcvf $ZIPED_LOGS $CUPS_DIR

su -c "$SCRIPTS_DIR/ruby_bootstrap.sh $SCRIPTS_DIR/upload_files_to_xxxx.rb $ZIPED_LOGS" $COMMON_USER

rm -Rf $CUPS_DIR/page_log*

service cups restart
