#!/bin/bash
# sidekiq    Init script for Sidekiq
# chkconfig: 345 100 75
#
# Description: Starts and Stops Sidekiq message processor for Stratus application.
#
# User-specified exit parameters used in this script:
#
# Exit Code 5 - Incorrect User ID
# Exit Code 6 - Directory not found


#Variable Set
APP="print_hub"
APP_DIR="/var/rails/${APP}/current"
APP_CONFIG="${APP_DIR}/config/sidekiq.yml"
LOG_FILE="$APP_DIR/log/sidekiq.log"
LOCK_FILE="$APP_DIR/tmp/${APP}-lock"
PID_FILE="$APP_DIR/tmp/sidekiq.pid"
GEMFILE="$APP_DIR/Gemfile"
SIDEKIQ="sidekiq"
APP_ENV="production"
CHRUBY_VERSION=$(cat $APP_DIR/chruby_version)
BUNDLE="/usr/local/bin/chruby-exec $CHRUBY_VERSION -- bundle"
APP_USER="deployer"
CURRENT_USER=$(whoami)

START_CMD="cd $APP_DIR && $BUNDLE exec $SIDEKIQ -C $APP_CONFIG -e $APP_ENV -d"
RETVAL=0

start() {

  status
  if [ $? -eq 1 ]; then

    [ -d $APP_DIR ] || (echo "$APP_DIR not found!.. Exiting"; exit 6)
    echo "Starting $SIDEKIQ message processor .. "
    if [ "$CURRENT_USER" = "root" ]; then
      eval "su - $APP_USER -c 'echo \"$START_CMD\" >> $LOG_FILE'"
      eval "su - $APP_USER -c '$START_CMD >> $LOG_FILE 2>&1 &'"
    else
      echo "$START_CMD" >> $LOG_FILE
      eval "$START_CMD >> $LOG_FILE 2>&1 &"
    fi
    RETVAL=$?
    #Sleeping for 8 seconds for process to be precisely visible in process table - See status ()
    sleep 8
    [ $RETVAL -eq 0 ] && touch $LOCK_FILE
    return $RETVAL
  else
    echo "$SIDEKIQ message processor is already running .. "
  fi


}

stop() {

    echo "Stopping $SIDEKIQ message processor .."
    SIG="INT"
    kill -$SIG `cat  $PID_FILE`
    RETVAL=$?
    [ $RETVAL -eq 0 ] && rm -f $LOCK_FILE
    return $RETVAL
}

status() {

  ps -ef | egrep 'sidekiq [0-9]+.[0-9]+.[0-9]+' | grep -v grep
  return $?
}


case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        stop
        while status > /dev/null
        do
             sleep 0.5
        done
        start
        ;;
    status)
        status

        if [ $? -eq 0 ]; then
             echo "$SIDEKIQ message processor is running .."
             RETVAL=0
         else
             echo "$SIDEKIQ message processor is stopped .."
             RETVAL=1
         fi
        ;;
    *)
        echo "Usage: $0 {start|stop|status}"
        exit 0
        ;;
esac
exit $RETVAL
