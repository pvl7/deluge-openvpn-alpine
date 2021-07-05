#!/usr/bin/env bash

set -euo pipefail

# not mandatory parameters
DELUGE_DAEMON_LOG_LEVEL=$(printenv DELUGE_DAEMON_LOG_LEVEL) || true
DELUGE_WEB_LOG_LEVEL=$(printenv DELUGE_WEB_LOG_LEVEL) || true
DELUGE_PORT=$(printenv DELUGE_PORT) || true
DELUGE_PASSWORD=$(printenv DELUGE_PASSWORD) || true

# setting default values
DELUGE_PORT=${DELUGE_PORT:-8112}
DELUGE_DAEMON_LOG_LEVEL=${DELUGE_DAEMON_LOG_LEVEL:-info}
DELUGE_WEB_LOG_LEVEL=${DELUGE_WEB_LOG_LEVEL:-info}
DELUGE_PASSWORD=${DELUGE_PASSWORD:-deluge}

deluge_daemon_port=58846
deluge_web_conf_template="deluge/web.conf.tpl"
deluge_web_conf="deluge/web.conf"

# clean up PID file if deluge crashed previously
rm -f /deluge/deluged.pid

# generating SHA1 salt and hash for Deluge password
PWD=$(python3 deluge/deluge_pwgen.py "${DELUGE_PASSWORD}")
PWD_SALT=$(echo "${PWD}" | cut -d':' -f1)
PWD_HASH=$(echo "${PWD}" | cut -d':' -f2)
export PWD_SALT PWD_HASH

# run variables substitution
cat "${deluge_web_conf_template}" | envsubst > ${deluge_web_conf}

# run deluge daemon
nohup /usr/bin/deluged -c /deluge -L "${DELUGE_DAEMON_LOG_LEVEL}" -l /deluge/deluged.log &

echo "[info] Waiting for Deluge daemon to get up and running..."

startup_timeout=30
while [[ $(netstat -ntl|grep "${deluge_daemon_port}"|grep LISTEN) == "" ]]; do
  echo "[INFO] Waiting for Deluge core process to come up...[${startup_timeout}]"
  sleep 1
  let "startup_timeout-=1"

  if [ "$startup_timeout" -lt 0 ] ; then
    echo "[ERROR] Deluge core process has failed to start. "
    exit 1
  fi
done

echo "[info] Deluge core daemon started"


# run deluge-web
nohup /usr/bin/deluge-web -c /deluge -L "${DELUGE_WEB_LOG_LEVEL}" -l /deluge/deluge-web.log &

startup_timeout=30
while [[ $(netstat -ntl | grep "${DELUGE_PORT}" | grep LISTEN) == "" ]]; do
  echo "[INFO] Waiting for Deluge Web UI process to come up...[${startup_timeout}]"
  sleep 1
  let "startup_timeout-=1"

  if [ "$startup_timeout" -lt 0 ] ; then
    echo "[ERROR] Deluge Web UI process has failed to start."
    exit 1
  fi
done

echo "[info] Deluge Web UI started"
