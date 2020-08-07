#!/bin/bash

set -eo pipefail

# Require to build docker image of other architectures
docker run --rm --privileged multiarch/qemu-user-static:register --reset

arch="$1"
version="$2"

case "$arch" in
amd64) base_image="balenalib/amd64-alpine:latest" ;;
386) base_image="balenalib/i386-alpine:latest" ;;
arm) base_image="balenalib/armv7hf-alpine:latest" ;;
esac

echo "Building...."
echo "Syncthing: $version ($arch)"

sed "1cFROM $base_image" Dockerfile >"Dockerfile.$arch"

docker build \
    -t "robertbeal/syncthing:$arch" \
    -t "robertbeal/syncthing:$arch.$version" \
    --build-arg=COMMIT_ID="$TRAVIS_COMMIT "\
    --build-arg=VERSION="$version" \
    --build-arg="ARCH=$arch" \
    --file "Dockerfile.$arch" .