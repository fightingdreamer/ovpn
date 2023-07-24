#!/bin/sh

set -e

cd ./conf
exec openvpn --config ./%{server_name}.conf
