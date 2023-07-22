#!/bin/sh

set -e

cd ./config/conf
exec openvpn --config ./%{client.name}.conf
