#!/bin/sh
### BEGIN INIT INFO
# Provides:          ksazd2aqua
# Required-Start:    $remote_fs $syslog
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Manage ksazd2aqua server
# Description:       Start, stop, restart thin server for ksazd2aqua application.
### END INIT INFO
set -e

# Feel free to change any of the following variables for your app:
TIMEOUT=${TIMEOUT-60}
APP_ROOT=/home/deployer/apps/ksazd2aqua
PID=$APP_ROOT/tmp/thin.pid
CMD="cd $APP_ROOT; bin/start"
AS_USER=deployer
set -u

sig () {
  test -s "$PID" && kill -$1 `cat $PID`
}

run () {
  if [ "$(id -un)" = "$AS_USER" ]; then
    eval $1
  else
    su -c "$1" - $AS_USER
  fi
}

case "$1" in
start)
  sig 0 && echo >&2 "Already running" && exit 0
  run "$CMD"
  ;;
stop)
  run "cd $APP_ROOT; bin/stop" && exit 0
  echo >&2 "Not running"
  ;;
restart|reload)
  run "cd $APP_ROOT; bin/restart" && echo reloaded OK && exit 0
  echo >&2 "Couldn't reload, starting '$CMD' instead"
  run "$CMD"
  ;;
*)
  echo >&2 "Usage: $0 <start|stop|restart>"
  exit 1
  ;;
esac
