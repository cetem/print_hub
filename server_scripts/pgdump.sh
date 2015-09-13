#!/bin/bash

BACKUP_DIR="/backup_postgres"
timestamp=`date -u '+%Y'.'%m'.'%d'_'%H'.'%M'.'%S'`

mkdir -m 777 -p "$BACKUP_DIR"
su -l postgres -c "/usr/bin/pg_dumpall | bzip2 > $BACKUP_DIR/backup_$timestamp.sql.bz2"
# Remove 5 days old backups
find $BACKUP_DIR -name "*.sql.bz2" -mtime +5 -exec rm {} \;
