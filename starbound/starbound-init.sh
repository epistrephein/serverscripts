#!/bin/sh
### BEGIN INIT INFO
# Provides:          starbound_server
# Required-Start:    $local_fs $network $named $time $syslog
# Required-Stop:     $local_fs $network $named $time $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Description:       Init script for starbound server
### END INIT INFO

start() {
  if [ "$(id -u)" != "0" ]; then
    { echo "Requires root privilege." >&2; }
    exit 1
  else
    if ps axf | grep -F ./starbound_server | grep -v grep >/dev/null; then
      echo "Starbound server is already running."
      exit 1
    else
      su -c "cd ~/starbound/linux64 && nohup ./starbound_server >/dev/null 2>&1 &" starbound
      echo "Starbound server starting."
    fi
  fi
}

stop() {
  if [ "$(id -u)" != "0" ]; then
    { echo "Requires root privilege." >&2; }
    exit 1
  else
    if ps axf | grep -F ./starbound_server | grep -v grep >/dev/null; then
      ps axf | grep -F ./starbound_server | grep -v grep | awk '{print "kill -INT " $1}' | sh >/dev/null 2>&1
      echo "Starbound server stopping."
    else
      echo "Starbound server is not running."
      exit 1
    fi
  fi
}

status() {
  if ps axf | grep -F ./starbound_server | grep -v grep >/dev/null; then
    echo "Starbound server is running."
  else
    echo "Starbound server is not running."
  fi
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  status)
    status
    ;;
  *)
    echo "Usage: $0 {start|stop|status}"
esac
