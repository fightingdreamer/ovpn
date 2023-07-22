#!/usr/bin/env ruby

require "JSON"
require "OpenSSL"
require "FileUtils"

def tls_extension(path)
  OpenSSL::X509::Certificate
    .new(File.read path)
    .extensions
    .map { |e| e.value }
    .filter { |e| e.start_with? "TLS" }
    .first
end

def r(path)
  File.read(path)
end

def w(path, content)
  parent_path, file_name = File.split path
  FileUtils.mkdir_p(parent_path)
  File.write(path, content)
end

def make(src, dst, path, vars)
  src_path = "#{src}/#{path}"
  dst_path = "#{dst}/#{path}" % vars
  src_content = File.read(src_path)
  dst_content = src_content % vars
  dir_path = File.split(dst_path).first
  FileUtils.mkdir_p(dir_path)
  File.write(dst_path, dst_content)
  return dst_path
end

def copy(src, dst)
  content = r(src)
  w(dst, content)
end

def fill(src, dst, vars)
  content = r(src)
  w(dst, content % vars)
end

def chmod(mode, dst)
  FileUtils.chmod(mode, dst)
end

def flatten_hash(val, path: "")
  return(
    {}.merge *val.map { |k, v| flatten(v, path: [path, k].join(".")) }.flatten
  )
end

def flatten_array(val, path: "")
  return { path => val.map { |v| flatten(val, path: path) }.to_h }
end

def flatten_any(val, path: "")
  return { path => val }
end

def flatten(val, path: "")
  return flatten_hash(val, path: path) if val.is_a?(Hash)
  return flatten_array(val, path: path) if val.is_a?(Array)
  return flatten_any(val, path: path)
end

def as_sym(hash)
  return hash.map { |k, v| [k.to_sym, v] }.to_h
end

def generate_server(server, clients)
  pki = "pki"
  src = "rb/templates/{server-name}"
  dst = "out/servers/#{server["name"]}"

  unless File.exist?("#{pki}/issued/#{server["name"]}.crt")
    system("ruby", "rb/cert.generate.server.rb", server["name"]) or
      abort("error")
  end

  fill(
    "#{src}/deploy.sh",
    "#{dst}/deploy.sh",
    as_sym(flatten(server, path: "server"))
  )
  copy("#{src}/container/Dockerfile", "#{dst}/container/Dockerfile")
  copy(
    "#{src}/container/root/opt/entrypoint.sh",
    "#{dst}/container/root/opt/entrypoint.sh"
  )
  fill(
    "#{src}/container/root/opt/openvpn/openvpn.conf",
    "#{dst}/container/root/opt/openvpn/openvpn.conf",
    as_sym(flatten(server, path: "server"))
  )
  for client in clients
    client_name = client["name"]
    s = as_sym flatten(server, path: "server")
    c = as_sym flatten(client, path: "client")
    v = {}.merge(s, c)
    fill(
      "#{src}/container/root/opt/openvpn/ccd/{client-name}",
      "#{dst}/container/root/opt/openvpn/ccd/#{client_name}",
      v
    )
  end
  copy(
    "#{src}/container/root/opt/openvpn/dhcp/pool.txt",
    "#{dst}/container/root/opt/openvpn/dhcp/pool.txt"
  )
  copy("#{pki}/dh.pem", "#{dst}/container/root/opt/openvpn/pki/dh.pem")
  copy("#{pki}/ca.crt", "#{dst}/container/root/opt/openvpn/pki/ca.crt")
  copy("#{pki}/crl.pem", "#{dst}/container/root/opt/openvpn/pki/crl.pem")
  copy(
    "#{pki}/issued/#{server["name"]}.crt",
    "#{dst}/container/root/opt/openvpn/pki/issued/#{server["name"]}.crt"
  )
  copy(
    "#{pki}/private/#{server["name"]}.key",
    "#{dst}/container/root/opt/openvpn/pki/private/#{server["name"]}.key"
  )
  chmod(
    0400,
    "#{dst}/container/root/opt/openvpn/pki/private/#{server["name"]}.key"
  )

  # src #{dst}/deploy.sh
  # src #{dst}/container/Dockerfile
  # src #{dst}/container/root/opt/entrypoint.sh
  # src #{dst}/container/root/opt/openvpn/openvpn.conf
  # gen #{dst}/container/root/opt/openvpn/ccd/#{client.name}
  # pki #{dst}/container/root/opt/openvpn/pki/dh.pem
  # pki #{dst}/container/root/opt/openvpn/pki/ca.crt
  # pki #{dst}/container/root/opt/openvpn/pki/clr.pem
  # pki #{dst}/container/root/opt/openvpn/pki/issued/{server.name}.crt
  # pki #{dst}/container/root/opt/openvpn/pki/private/{server.name}.key
end

def generate_client(server, client)
  pki = "pki"
  src = "rb/templates/{client-name}"
  dst = "out/clients/#{client["name"]}"

  unless File.exist?("#{pki}/issued/#{client["name"]}.crt")
    system("ruby", "rb/cert.generate.client.rb", client["name"]) or
      abort("error")
  end

  fill(
    "#{src}/deploy.sh",
    "#{dst}/deploy.sh",
    as_sym(flatten(client, path: "client"))
  )
  copy("#{src}/container/Dockerfile", "#{dst}/container/Dockerfile")
  copy(
    "#{src}/container/root/opt/entrypoint.sh",
    "#{dst}/container/root/opt/entrypoint.sh"
  )
  fill(
    "#{src}/container/root/opt/openvpn/openvpn.conf",
    "#{dst}/container/root/opt/openvpn/openvpn.conf",
    {}.merge(
      as_sym(flatten(client, path: "client")),
      as_sym(flatten(server, path: "server"))
    )
  )
  copy("#{pki}/dh.pem", "#{dst}/container/root/opt/openvpn/pki/dh.pem")
  copy("#{pki}/ca.crt", "#{dst}/container/root/opt/openvpn/pki/ca.crt")
  copy(
    "#{pki}/issued/#{client["name"]}.crt",
    "#{dst}/container/root/opt/openvpn/pki/issued/#{client["name"]}.crt"
  )
  copy(
    "#{pki}/private/#{client["name"]}.key",
    "#{dst}/container/root/opt/openvpn/pki/private/#{client["name"]}.key"
  )

  # src {dst}/deploy.sh
  # src {dst}/container/Dockerfile
  # src {dst}/container/root/opt/entrypoint.sh
  # src {dst}/container/root/opt/openvpn/openvpn.conf
  # pki {dst}/container/root/opt/openvpn/pki/ca.crt
  # pki {dst}/container/root/opt/openvpn/pki/issued/{client-name}.crt
  # pki {dst}/container/root/opt/openvpn/pki/private/{client-name}.key

  fill(
    "#{src}/run.conf.sh",
    "#{dst}/run.conf.sh",
    as_sym(flatten(client, path: "client"))
  )
  fill(
    "#{src}/run.ovpn.sh",
    "#{dst}/run.ovpn.sh",
    as_sym(flatten(client, path: "client"))
  )
  fill(
    "#{src}/config/conf/{client-name}.conf",
    "#{dst}/config/conf/#{client["name"]}.conf",
    {}.merge(
      as_sym(flatten(client, path: "client")),
      as_sym(flatten(server, path: "server"))
    )
  )
  copy("#{pki}/ca.crt", "#{dst}/config/conf/pki/ca.crt")
  copy(
    "#{pki}/issued/#{client["name"]}.crt",
    "#{dst}/config/conf/pki/issued/#{client["name"]}.crt"
  )
  copy(
    "#{pki}/private/#{client["name"]}.key",
    "#{dst}/config/conf/pki/private/#{client["name"]}.key"
  )
  chmod(0400, "#{dst}/config/conf/pki/private/#{client["name"]}.key")
  fill(
    "#{src}/config/ovpn/{client-name}.ovpn",
    "#{dst}/config/ovpn/#{client["name"]}.ovpn",
    {}.merge(
      as_sym(flatten(client, path: "client")),
      as_sym(flatten(server, path: "server")),
      {
        "ca.crt.content": r("#{pki}/ca.crt").strip,
        "client.issued.crt.content":
          r("#{pki}/issued/#{client["name"]}.crt").strip,
        "client.private.key.content":
          r("#{pki}/private/#{client["name"]}.key").strip
      }
    )
  )
  chmod(0400, "#{dst}/config/ovpn/#{client["name"]}.ovpn")

  # src {dst}/config/openvpn.conf
  # pki {dst}/config/keys/ca.crt
  # pki {dst}/config/keys/issued/{client-name}.crt
  # pki {dst}/config/keys/private/{client-name}.key
end

system("rm", "-rfv", "out") or abort("error")
system("mkdir", "-p", "out") or abort("error")

config = JSON.load_file "config.json"
server = config["server"]
clients = config["clients"]
generate_server server, clients
clients.each { |client| generate_client server, client }
# todo: drop unused issued cerificates

# Dir
#   .glob("pki/issued/*.crt")
#   .map do |path|
#     name = File.basename(path, File.extname(path))
#     ext = tls_extension(path)
#     generate_server(name, $config) if ext.include?("Server")
#     generate_client(name, $config) if ext.include?("Client")
#   end
