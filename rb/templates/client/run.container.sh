#!/bin/sh

set -e

podman build \
 --tag "openvpn-client-%{client_name}" \
 container

podman run \
  -ti \
  --rm \
  --cap-add=NET_ADMIN \
  --device /dev/net/tun \
  --name "openvpn-client-%{client_name}" \
  "openvpn-client-%{client_name}"
