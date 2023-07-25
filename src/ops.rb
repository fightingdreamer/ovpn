def _var_client_pki(pki, client_name)
  {
    "ca.crt": File.read("#{pki}/ca.crt").strip,
    "client_issued.crt": File.read("#{pki}/issued/#{client_name}.crt").strip,
    "client_private.key": File.read("#{pki}/private/#{client_name}.key").strip
  }
end

def ops_server(env, var_server, var_clients)
  server_name = var_server[:server_name]
  pki = env[:pki]
  tpl = "#{env[:tpl]}/server"
  out = "#{env[:out]}/servers/#{server_name}"

  [
    # ./conf
    { src: "#{tpl}/run_conf.sh", dst: "#{out}/run_conf.sh", var: var_server },
    {
      src: "#{tpl}/conf/%(server_name).conf",
      dst: "#{out}/conf/#{server_name}.conf",
      var: var_server
    },
    { src: "#{tpl}/conf/dhcp/pool.txt", dst: "#{out}/conf/dhcp/pool.txt" },
    *var_clients.map do |var_client|
      client_name = var_client[:client_name]
      {
        src: "#{tpl}/conf/ccd/%(client_name)",
        dst: "#{out}/conf/ccd/#{client_name}",
        var: {}.merge(var_server, var_client)
      }
    end,
    { src: "#{pki}/dh.pem", dst: "#{out}/conf/pki/dh.pem" },
    { src: "#{pki}/ca.crt", dst: "#{out}/conf/pki/ca.crt" },
    { src: "#{pki}/crl.pem", dst: "#{out}/conf/pki/crl.pem" },
    {
      src: "#{pki}/issued/#{server_name}.crt",
      dst: "#{out}/conf/pki/issued/#{server_name}.crt"
    },
    {
      src: "#{pki}/private/#{server_name}.key",
      dst: "#{out}/conf/pki/private/#{server_name}.key",
      mod: 0o600
    },
    # container
    {
      src: "#{tpl}/run_container.sh",
      dst: "#{out}/run_container.sh",
      var: var_server
    },
    { src: "#{tpl}/container/Dockerfile", dst: "#{out}/container/Dockerfile" },
    {
      src: "#{tpl}/container/root/opt/entrypoint.sh",
      dst: "#{out}/container/root/opt/entrypoint.sh"
    },
    {
      src: "#{tpl}/container/root/opt/openvpn/openvpn.conf",
      dst: "#{out}/container/root/opt/openvpn/openvpn.conf",
      var: var_server
    },
    {
      src: "#{tpl}/container/root/opt/openvpn/dhcp/pool.txt",
      dst: "#{out}/container/root/opt/openvpn/dhcp/pool.txt"
    },
    *var_clients.map do |var_client|
      client_name = var_client[:client_name]
      {
        src: "#{tpl}/container/root/opt/openvpn/ccd/%(client_name)",
        dst: "#{out}/container/root/opt/openvpn/ccd/#{client_name}",
        var: {}.merge(var_server, var_client)
      }
    end,
    {
      src: "#{pki}/dh.pem",
      dst: "#{out}/container/root/opt/openvpn/pki/dh.pem"
    },
    {
      src: "#{pki}/ca.crt",
      dst: "#{out}/container/root/opt/openvpn/pki/ca.crt"
    },
    {
      src: "#{pki}/crl.pem",
      dst: "#{out}/container/root/opt/openvpn/pki/crl.pem"
    },
    {
      src: "#{pki}/issued/#{server_name}.crt",
      dst: "#{out}/container/root/opt/openvpn/pki/issued/#{server_name}.crt"
    },
    {
      src: "#{pki}/private/#{server_name}.key",
      dst: "#{out}/container/root/opt/openvpn/pki/private/#{server_name}.key",
      mod: 0o600
    }
  ]
end

def ops_client(env, var_server, var_client)
  client_name = var_client[:client_name]
  pki = env[:pki]
  tpl = "#{env[:tpl]}/client"
  out = "#{env[:out]}/clients/#{client_name}"
  var_client_pki = _var_client_pki(pki, client_name)

  [
    # ./conf
    { src: "#{tpl}/run_conf.sh", dst: "#{out}/run_conf.sh", var: var_client },
    {
      src: "#{tpl}/conf/%(client_name).conf",
      dst: "#{out}/conf/#{client_name}.conf",
      var: {}.merge(var_server, var_client)
    },
    { src: "#{pki}/ca.crt", dst: "#{out}/conf/pki/ca.crt" },
    {
      src: "#{pki}/issued/#{client_name}.crt",
      dst: "#{out}/conf/pki/issued/#{client_name}.crt"
    },
    {
      src: "#{pki}/private/#{client_name}.key",
      dst: "#{out}/conf/pki/private/#{client_name}.key",
      mod: 0o600
    },
    # ./ovpn
    { src: "#{tpl}/run_ovpn.sh", dst: "#{out}/run_ovpn.sh", var: var_client },
    {
      src: "#{tpl}/ovpn/%(client_name).ovpn",
      dst: "#{out}/ovpn/#{client_name}.ovpn",
      var: {}.merge(var_server, var_client, var_client_pki),
      mod: 0o600
    },
    # ./container
    {
      src: "#{tpl}/run_container.sh",
      dst: "#{out}/run_container.sh",
      var: var_client
    },
    { src: "#{tpl}/container/Dockerfile", dst: "#{out}/container/Dockerfile" },
    {
      src: "#{tpl}/container/root/opt/entrypoint.sh",
      dst: "#{out}/container/root/opt/entrypoint.sh"
    },
    {
      src: "#{tpl}/container/root/opt/openvpn/openvpn.conf",
      dst: "#{out}/container/root/opt/openvpn/openvpn.conf",
      var: {}.merge(var_server, var_client)
    },
    {
      src: "#{pki}/ca.crt",
      dst: "#{out}/container/root/opt/openvpn/pki/ca.crt"
    },
    {
      src: "#{pki}/issued/#{client_name}.crt",
      dst: "#{out}/container/root/opt/openvpn/pki/issued/#{client_name}.crt"
    },
    {
      src: "#{pki}/private/#{client_name}.key",
      dst: "#{out}/container/root/opt/openvpn/pki/private/#{client_name}.key",
      mod: 0o600
    }
  ]
end
