# Ovpnc

Simple tool to manage your OpenVPN keys and certs in a deterministic way.

## Description

This tool was created to follow `nix` way to doing things, create config once and ensure that generated state will follow.

Any changes to config will be reflected by matching changes in generated state:
- `./pki` is updated
- `./out` is generated

## Dependencies
| name     | version |
| :---     | :---    |
| ruby     | ^3      |
| easy_rsa | ^3.1    |

## Features
- fully deterministic
- can generate config for `openvpn` system service (Linux)
- can generate config for `OpenVPN` clients as `*.ovpn`
- can generate `Dockerfile` for client and server
- includes simple `run_*.sh` scripts that just-works

## Default config
```json
{
  "server": {
    "name": "my-server-name",
    "public": {
      "ip": "my-domain-name.com",
      "port": "1194"
    },
    "local": {
      "ip": "0.0.0.0",
      "port": "1194"
    },
    "vpn": {
      "gateway": "172.16.0.1",
      "netmask": "255.255.255.0",
      "dhcp": {
        "pool": {
          "begin": "172.16.0.100",
          "end": "172.16.0.254"
        }
      }
    },
    "crypto": {
      "cipher": "CHACHA20-POLY1305"
    }
  },
  "clients": [
    {
      "name": "my-client-name",
      "vpn": {
        "ip": "172.16.0.2"
      }
    }
  ]
}
```

## Default flow
```bash
git clone https://github.com/fightingdreamer/ovpnc.git && cd ovpnc

# create default config.json
ruby ovpnc.rb config_init

# edit your config.json

# create needed CA, DH, certs and keys in `./pki` dir
# create `server` and `clients` ready to use configs in `./out` dir
ruby ovpnc.rb config_sync

# optionally edit your config.json here again

# push clients no longer present in config to revoke list
# generate keys/certs for new clients
# create `server` and `clients` ready to use configs
ruby ovpnc.rb config_sync
```

## Run server
```bash
# run openvpn server
cd ./out/servers/my-server-name
sh run_conf.sh

# run openvpn server in podman/docker
cd ./out/servers/my-server-name
sh run_container.sh
```

## Run client
```bash
# run openvpn client
cd ./out/servers/my-client-name
sh run_conf.sh

# run openvpn client in podman/docker
cd ./out/servers/my-client-name
sh run_container.sh

# run openvpn client from '*.ovpn' file
cd ./out/servers/my-client-name
sh run_ovpn.sh
```
