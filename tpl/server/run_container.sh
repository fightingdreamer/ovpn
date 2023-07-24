#!/bin/sh

set -e

podman build \
 --tag "openvpn-server-%{server_name}" \
 container

podman run \
  -ti \
  --rm \
  --cap-add=NET_ADMIN \
  --cap-add=SYS_MODULE \
  --sysctl="net.ipv4.conf.all.src_valid_mark=1" \
  --sysctl="net.ipv4.conf.all.forwarding=1" \
  --device /dev/net/tun \
  --publish "%{server_local_ip}:%{server_local_port}:%{server_local_port}/udp" \
  --name "openvpn-server-%{server_name}" \
  "openvpn-server-%{server_name}"
