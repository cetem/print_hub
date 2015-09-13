#!/bin/bash

COMMON_USER=/home/common_user
LAST_FILE=$(ls -a /backup_postgres |grep .sql.bz2 | tail -n1)

$COMMON_USER/scripts/ruby_bootstrap.sh $COMMON_USER/scripts/upload_files_to_mega.rb /backup_postgres/$LAST_FILE
