#!/bin/bash

set -euo pipefail

arch="$1"

case "$arch" in
    i386 ) base_image="resin/i386-alpine" ;;
    amd64 ) base_image="alpine:3.9" ;;
    arm ) base_image="resin/rpi-alpine" ;;
    arm64 ) base_image="resin/aarch64-alpine" ;;
esac

sed "s@alpine:\\([0-9]\\+\\).\\([0-9]\\+\\)@$base_image@g" Dockerfile > "Dockerfile.$arch"

