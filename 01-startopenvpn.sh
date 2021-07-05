#!/usr/bin/env bash

set -euo pipefail

openvpn_work_dir="/etc/openvpn"
openvpn_credentials_file="credentials.txt"
openvpn_config_file="openvpn-client.ovpn"

# mandatory parameters
OVPN_USER=$(printenv OVPN_USER)
OVPN_USER=$(printenv OVPN_USER)
LAN_NETWORK_CIDR=$(printenv LAN_NETWORK_CIDR)

# not mandatory parameters
OVPN_ENABLED=$(printenv OVPN_ENABLED) || true
OVPN_LOG_LEVEL=$(printenv OVPN_LOG_LEVEL) || true
OVPN_EXTRA_PARAMS=$(printenv OVPN_EXTRA_PARAMS) || true

# setting default values
OVPN_LOG_LEVEL=${OVPN_LOG_LEVEL:-3}

# check if VPN is enabled then run all the commands
if [[ "${OVPN_ENABLED}" == "true" ]] ; then

  # some pre-flight checklist
  if [[ ${OVPN_USER} == "" ]] || [[ ${OVPN_SECRET} == "" ]] ; then
    echo "[ERROR] OpenVPN credentials are missing. Please define OVPN_USER and OVPN_SECRET environment variables."
    exit 1
  fi

  if [ ! -f ${openvpn_work_dir}/${openvpn_config_file} ] ; then
    echo "[ERROR] OpenVPN configuration file is missing."
    exit 1
  fi

  if [[ ${LAN_NETWORK_CIDR} == "" ]] ; then
    echo "[ERROR] LAN_NETWORK_CIDR parameter is not defined."
    exit 1
  fi

  # create missing DEV/TUN device
  mkdir -p /dev/net

  if [ ! -c /dev/net/tun ]; then
      mknod /dev/net/tun c 10 200
  fi

  # create credentials file
  echo "${OVPN_USER}" > ${openvpn_work_dir}/${openvpn_credentials_file}
  echo "${OVPN_SECRET}" >> ${openvpn_work_dir}/${openvpn_credentials_file}

  echo "[INFO] OpenVPN is starting..."

  # start OpenVPN client
  nohup openvpn --config ${openvpn_work_dir}/${openvpn_config_file} \
    --auth-user-pass ${openvpn_work_dir}/${openvpn_credentials_file} \
    --verb ${OVPN_LOG_LEVEL} \
    ${OVPN_EXTRA_PARAMS} \
  &

  startup_timeout=30

  while [[ $(ps -ef|grep "\d\sopenvpn") == "" ]] ; do
    echo "[INFO] Waiting for OpenVPN to come up...[${startup_timeout}]"
    sleep 1
    let "startup_timeout-=1"

    if [ "$startup_timeout" -lt 0 ] ; then
      echo "[ERROR] OpenVPN has failed to start. "
      exit 1
    fi
  done

  # local network traffic should be routed back via the docker interface
  docker_network_default_gw=$(ip -4 route ls | grep default | cut -d' ' -f3 | xargs)
  docker_interface=$(ip -4 route ls | grep default | cut -d' ' -f5 | xargs)

  if [[ ${docker_network_default_gw} != "" ]] && [[ ${docker_interface} != "" ]] ; then
    ip route add "${LAN_NETWORK_CIDR}" via "${docker_network_default_gw}" dev "${docker_interface}"
  else
    echo "[ERROR] Failed to add LAN routes."
    exit 1
  fi

  echo "[INFO] OpenVPN is running."

else

  echo "[INFO] OpenVPN is not enabled, not starting..."

fi




