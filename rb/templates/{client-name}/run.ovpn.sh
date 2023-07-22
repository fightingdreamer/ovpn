#!/bin/sh

set -e

cd ./config/ovpn
exec openvpn --config ./%{client.name}.ovpn
