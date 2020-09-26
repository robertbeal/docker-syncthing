#!/bin/sh
set -e

if [ -n "${PGID}" ]; then
    groupmod -o -g "$PGID" syncthing
fi

if [ -n "${PUID}" ]; then
    usermod -o -u "$PUID" syncthing
fi

if [ "$(id -u)" = '0' ]; then
    chown -R syncthing /config
    exec su-exec syncthing /usr/bin/syncthing "$@"
else
    exec /usr/bin/syncthing "$@"
fi
