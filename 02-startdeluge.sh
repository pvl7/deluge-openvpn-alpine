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
deluge_work_dir="/deluge"

deluge_core_conf_template="/deluge-config-template/core.conf.tpl"
deluge_web_conf_template="/deluge-config-template/web.conf.tpl"
deluge_web_conf="${deluge_work_dir}/web.conf"
deluge_core_conf="${deluge_work_dir}/core.conf"

# clean up PID file if deluge crashed previously
rm -f "${deluge_work_dir}/deluged.pid"

# if the destination file exists, skip web UI config
if [ ! -f "${deluge_web_conf}" ] ; then
  # generating SHA1 salt and hash for Deluge password
  PWD=$(python3 /deluge-config-template/deluge_pwgen.py "${DELUGE_PASSWORD}")
  PWD_SALT=$(echo "${PWD}" | cut -d':' -f1)
  PWD_HASH=$(echo "${PWD}" | cut -d':' -f2)
  export PWD_SALT PWD_HASH

  # run variables substitution
  cat "${deluge_web_conf_template}" | envsubst > ${deluge_web_conf}
  unset PWD_SALT PWD_HASH
fi

# if the destination file exists, skip deluge daemon config
if [ ! -f "${deluge_core_conf}" ] ; then
  # run variables substitution
  cat "${deluge_core_conf_template}" | envsubst > ${deluge_core_conf}
fi

# run deluge daemon
nohup /usr/bin/deluged -c "${deluge_work_dir}" -L "${DELUGE_DAEMON_LOG_LEVEL}" 2>&1 &

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
nohup /usr/bin/deluge-web -c "${deluge_work_dir}" -L "${DELUGE_WEB_LOG_LEVEL}" 2>&1 &

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
