#!/bin/sh

set -e

exec openvpn --config /opt/openvpn/openvpn.conf
