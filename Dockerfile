FROM alpine:edge AS envsubst
MAINTAINER Pavel Lu <email@pavel.lu>

ENV OPENVPN_VERSION="2.5.3-r0"
ENV DELUGE_VERSION="2.0.3-r7"
ENV LANG en_US.UTF-8

ENV BUILD_DEPS="gettext"
ENV BUILD_PKGS="libintl"

RUN set -x && \
    apk add --update $BUILD_PKGS && \
    apk add --virtual build_deps $BUILD_DEPS &&  \
    cp /usr/bin/envsubst /usr/local/bin/envsubst && \
    apk del build_deps

FROM envsubst AS alpine-openvpn
RUN apk add --no-cache bash openvpn=$OPENVPN_VERSION
COPY 01-startopenvpn.sh /01-startopenvpn.sh

FROM alpine-openvpn AS deluge
RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing deluge=$DELUGE_VERSION && \
    apk add --no-cache py3-setuptools

COPY 02-startdeluge.sh /02-startdeluge.sh
COPY start.sh /start.sh
COPY deluge /deluge

CMD ["/start.sh"]
