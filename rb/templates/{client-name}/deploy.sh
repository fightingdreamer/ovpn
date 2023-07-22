#!/bin/sh

set -e
name="openvpn-client-%{client.name}"

podman build \
 --tag "$name" \
 container

podman run \
  -ti \
  --rm \
  --cap-add=NET_ADMIN \
  --device /dev/net/tun \
  --name "$name" \
  "$name"
