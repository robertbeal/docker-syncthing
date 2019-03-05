[![Build Status](https://travis-ci.org/robertbeal/docker-syncthing.svg?branch=master)](https://travis-ci.org/robertbeal/syncthing)
[![](https://images.microbadger.com/badges/image/robertbeal/syncthing.svg)](https://microbadger.com/images/robertbeal/syncthing "Get your own image badge on microbadger.com")
[![](https://images.microbadger.com/badges/version/robertbeal/syncthing.svg)](https://microbadger.com/images/robertbeal/syncthing "Get your own version badge on microbadger.com")
[![](https://img.shields.io/docker/pulls/robertbeal/syncthing.svg)](https://hub.docker.com/r/robertbeal/syncthing/)
[![](https://img.shields.io/docker/stars/robertbeal/syncthing.svg)](https://hub.docker.com/r/robertbeal/syncthing/)
[![](https://img.shields.io/docker/automated/robertbeal/syncthing.svg)](https://hub.docker.com/r/robertbeal/syncthing/)

# Syncthing

A production optimised version of Syncthing, able to run in `--read-only` mode and `su-exec` for managing the user is runs as.

## Running in read-only mode

Runs using a user `syncthing:770`, so there are a number of options for running the container...

1. Create a host user with matching UID and run the container via that user:

`sudo useradd --no-create-home --system --shell /bin/false --uid 770 foo`

```bash
docker run \
    --name syncthing \
    --init \
    --user $(id foo -u):$(id foo -g) \
    --rm \
    --read-only \
    --security-opt="no-new-privileges:true" \
    --net=host \
    --health-cmd="curl --fail -H \"X-API-Key: $(cat /root/syncthing-api-key)\" http://127.0.0.1:8384/rest/system/ping || exit 1" \
    --health-interval=30s \
    --health-retries=3 \
    -v /home/syncthing/config:/config \
    -v /home/syncthing/data:/data \
    -p 127.0.0.1:8384:8384 \
    -p 22000:22000 \
    -p 21027:21027/udp \
    robertbeal/syncthing
```

1. Mount `/etc/passwd` and create a host user with matching name:

`sudo useradd --no-create-home --system --shell /bin/false syncthing`

```bash
docker run \
    --name syncthing \
    --init \
    --rm \
    --read-only \
    --security-opt="no-new-privileges:true" \
    --net=host \
    --health-cmd="curl --fail -H \"X-API-Key: $(cat /root/syncthing-api-key)\" http://127.0.0.1:8384/rest/system/ping || exit 1" \
    --health-interval=30s \
    --health-retries=3 \
    -v /etc/passwd:/etc/passwd:ro \
    -v /home/syncthing/config:/config \
    -v /home/syncthing/data:/data \
    -p 127.0.0.1:8384:8384 \
    -p 22000:22000 \
    -p 21027:21027/udp \
    robertbeal/syncthing
```

1. Using `--user` but without a matching host UID/GID so could cause issues:

```bash
docker run \
    --name syncthing \
    --init \
    --rm \
    --read-only \
    --security-opt="no-new-privileges:true" \
    --net=host \
    --health-cmd="curl --fail -H \"X-API-Key: $(cat /root/syncthing-api-key)\" http://127.0.0.1:8384/rest/system/ping || exit 1" \
    --health-interval=30s \
    --health-retries=3 \
    --user $(id foo -u):$(id foo -g) \
    -v /home/syncthing/config:/config \
    -v /home/syncthing/data:/data \
    -p 127.0.0.1:8384:8384 \
    -p 22000:22000 \
    -p 21027:21027/udp \
    robertbeal/syncthing
```

## Running in writable mode

It is possible to define a UID and GID to the container but `--read-only` won't be possible as it modifies `/etc/passwd`. This is done using `usermod` (via the `shadow` package in alpine):

```bash
docker run \
    --name syncthing \
    --init \
    --rm \
    --read-only \
    --security-opt="no-new-privileges:true" \
    --net=host \
    --health-cmd="curl --fail -H \"X-API-Key: $(cat /root/syncthing-api-key)\" http://127.0.0.1:8384/rest/system/ping || exit 1" \
    --health-interval=30s \
    --health-retries=3 \
    -e PUID=$(id -u) \
    -e PGID=$(id -g) \
    -v /home/syncthing/config:/config \
    -v /home/syncthing/data:/data \
    -p 127.0.0.1:8384:8384 \
    -p 22000:22000 \
    -p 21027:21027/udp \
    robertbeal/syncthing
```

## Tests

To run the container tests, run the following:

```bash
pip install --user --upgrade pip pipenv
pipenv install -d
pipenv run pytest -v
```
