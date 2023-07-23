#!/bin/sh

set -e

cd ./config/conf
exec openvpn --config ./%{client_name}.conf
