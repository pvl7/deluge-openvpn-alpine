# OpenVPN and Deluge lightweight solution
A lighweight version of Deluge and OpenVPN running in the same container and powered by Alpine linux.

# Description

There are numerous solutions like this one available, however most of them did not suit me for different reasons. 

The main requirements were:
* The ability to run the solution on my NAS Synology DS415+ in the Docker container. This one can be tricky. I spent a lot of time trying various solutions but being an enthusiastic person, I eventually started my own project.
* Compact Docker image size. It is just convenient and the right way of doing containers.
* Simple solution to configure and to maintain. Most of available solutions are great and convering a lot of existing VPN providers. I have only one at the moment and don't need this level of flexibility just yet. At the end of the day all you need to do is just to pass your OpenVPN config to your configuration regardless of what VPN provider it is.

This is how this project was born.

# How to use it

## Docker Compose (recommended)

```
version: '3'

services:
  deluge-openvpn-alpine:
    image: pvl7/deluge-openvpn-alpine:tagname
    container_name: deluge-openvpn-alpine
    cap_add:
      - NET_ADMIN
    devices:
      - /dev/net/tun
    environment:
      - OVPN_USER=<insert>
      - OVPN_SECRET=<insert>
      - OVPN_ENABLED=true
      - LAN_NETWORK_CIDR=<insert>
    volumes:
      - /path/to/your/openvpn-client.ovpn:/etc/openvpn/openvpn-client.ovpn:ro
      - /path/to/downloads:/data
      - /path/to/deluge/workdir:/deluge
    ports:
      - 8112:8112/tcp
    restart: unless-stopped
```

then run the following command:
`docker-compose up -d`

<b>Note for Synology users</b>

I was only able to run this successfully on Synology using this way (via ssh and command line tools). The container apperas in the Docker UI and works perfectly. However, it does not work if you create a new container from Docker UI even with elevated privileges - the OpenVPN does not start for unknown reasons (possibly because of I have DSM 7 running on my NAS).

## Docker run

```
docker run -it \
  --cap-add NET_ADMIN \
  -e OVPN_USER=<insert> \
  -e OVPN_SECRET=<insert> \
  -e OVPN_ENABLED=true \
  -e LAN_NETWORK_CIDR=<Your LAN CIDR> \
  -v "/path/to/your/openvpn-client.ovpn:/etc/openvpn/openvpn-client.ovpn" \
  -v "/path/to/downloads:/data" \
  -v "/path/to/deluge/workdir:/deluge" \
  -p 8112:8112/tcp \
  --rm \
  -d \
  --name deluge-openvpn-alpine \
  pvl7/deluge-openvpn-alpine:tagname
```


# Supported environment variables

| Variable | Description |
| :----: | --- |
| `OVPN_ENABLED=true` | Enables OpenVPN. Any other value or omitted variable won't start the OpenVPN daemon |
| `OVPN_USER` | Your VPN provider user name. OpenVPN will ignore the user/pass authentication if not provided  |
| `OVPN_PASS` | Your VPN provider user password. OpenVPN will ignore the user/pass authentication if not provided  |
| `OVPN_LOG_LEVEL` | OpenVPN logs verbosity level (3 is by default)|
| `OVPN_EXTRA_PARAMS` | To make life easier if some extra OpenVPN parameters are required |
| `DELUGE_DAEMON_LOG_LEVEL` | Deluge daemon logs verbosity level (`info` is by default) |
| `DELUGE_WEB_LOG_LEVEL` | Deluge web UI logs verbosity level (`info` is by default) |
| `DELUGE_PASSWORD` | If you wish to change the default Deluge web UI password |

# Supported architectures

<b>x86-64</b> only as of now

# TODO

- Run Deluge as non-root
- Add health checks


