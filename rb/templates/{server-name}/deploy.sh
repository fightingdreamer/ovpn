#!/bin/sh

set -e
name="openvpn-server-%{server.name}"

podman build \
 --tag "$name" \
 container

podman run \
  -ti \
  --rm \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
  --sysctl="net.ipv4.conf.all.forwarding=1" \
  --device /dev/net/tun \
  --publish "%{server.local.ip}:%{server.local.port}:%{server.local.port}/udp" \
  --name "$name" \
  "$name"
