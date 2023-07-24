#!/bin/sh

set -e

cd ./conf
exec openvpn --config ./%{client_name}.conf
