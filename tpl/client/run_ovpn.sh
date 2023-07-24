#!/bin/sh

set -e

cd ./ovpn
exec openvpn --config ./%{client_name}.ovpn
