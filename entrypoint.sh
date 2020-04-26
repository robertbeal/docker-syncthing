#!/bin/sh
set -e

if [[ -v "${PGID}" ]]; then
    groupmod -o -g "$PGID" syncthing
fi

if [[ -v "${PUID}" ]]; then
    usermod -o -u "$PUID" syncthing
fi

if [ "$(id -u)" = '0' ]; then
    chown -R syncthing /config
    exec su-exec syncthing /usr/local/bin/syncthing "$@"
fi

exec /usr/local/bin/syncthing "$@"
