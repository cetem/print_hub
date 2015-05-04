#!/bin/bash
### BEGIN INIT INFO
# Provides: unicorn
# Required-Start: $all
# Required-Stop: $network $local_fs $syslog
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Start the unicorns at boot
# Description: Enable at boot time.
### END INIT INFO

set -e

APPS=(abaco print_hub)

sig () {
  test -s "$PID" && kill -$1 `cat "$PID"`
}

oldsig () {
  test -s "$OLD_PID" && kill -$1 `cat "$OLD_PID"`
}

cmd () {

  case $1 in
    start)
      sig 0 && echo >&2 "Already running" && return 0
      run_cmd_as_app_user
      echo "Starting"
      ;;
    stop)
      sig QUIT && echo "Stopping" && return 0
      echo >&2 "Not running"
      ;;
    force-stop)
      sig TERM && echo "Forcing a stop" && return 0
      echo >&2 "Not running"
      ;;
    restart|reload)
      sig USR2 && sleep 5 && oldsig QUIT && echo "Killing old master" `cat $OLD_PID` && return 0
      echo >&2 "Couldn't reload, starting '$CMD' instead"
      run_cmd_as_app_user
      ;;
    upgrade)
      sig USR2 && echo Upgraded && return 0
      echo >&2 "Couldn't upgrade, starting '$CMD' instead"
      run_cmd_as_app_user
      ;;
    rotate)
            sig USR1 && echo rotated logs OK && return 0
            echo >&2 "Couldn't rotate logs" && return 1
            ;;
    *)
      echo >&2 "Usage: $0 <start|stop|restart|upgrade|rotate|force-stop>"
      exit 1
      ;;
    esac
}

run_cmd_as_app_user () {
  echo "running for $APP_USER: $CMD"
  eval "su - $APP_USER -c '$CMD'"
}

setup () {
  export APP_NAME=$1
  export APP_USER="deployer"
  export RAILS_ROOT="/var/rails/$APP_NAME/current"
  export UNICORN_CONFIG="config/unicorn.rb"
  export RAILS_ENV="production"
  export UNICORN="bundle exec unicorn"

  echo "Launching ${APP_NAME}"

  # If unicorn binary was not defined in config

  export PID=/tmp/pids.$APP_NAME.unicorn.pid
  export OLD_PID="$PID.oldbin"

  CMD="cd $RAILS_ROOT && $UNICORN -E ${RAILS_ENV} -c ${UNICORN_CONFIG} -D"
  return 0
}

for app in ${APPS[*]}; do
  setup $app
  cmd $1
done
