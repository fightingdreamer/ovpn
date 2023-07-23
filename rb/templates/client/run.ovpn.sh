#!/bin/sh

set -e

cd ./config/ovpn
exec openvpn --config ./%{client_name}.ovpn
