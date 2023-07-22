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

def cpy(src, dst, path, vars = {}, vars_in_src_path = false)
  if vars_in_src_path
    src_path = "#{src}/#{path}" % vars
  else
    src_path = "#{src}/#{path}"
  end
  dst_path = "#{dst}/#{path}" % vars
  src_content = File.read(src_path)
  dst_content = src_content % vars
  dir_path = File.split(dst_path).first
  FileUtils.mkdir_p(dir_path)
  File.write(dst_path, dst_content)
  puts "created #{dst_path}"
  return dst_path
end

def mod(dst, path, mode, vars = {})
  dst_path = "#{dst}/#{path}" % vars
  FileUtils.chmod(mode, dst_path)
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
  src = "rb/templates/server"
  dst = "out/servers/%{server.name}"
  vpn = "out/servers/%{server.name}/container/root/opt/openvpn"

  server_vars = as_sym(flatten(server, path: "server"))

  unless File.exist?("pki/issued/%{server.name}.crt" % server_vars)
    system("ruby", "rb/cert.generate.server.rb", server["name"]) or
      abort("error")
  end

  cpy(src, dst, "deploy.sh", server_vars)
  cpy(src, dst, "container/Dockerfile", server_vars)
  cpy(src, dst, "container/root/opt/entrypoint.sh", server_vars)
  cpy(src, dst, "container/root/opt/openvpn/openvpn.conf", server_vars)
  for client in clients
    client_vars = as_sym flatten(client, path: "client")
    vars = {}.merge(server_vars, client_vars)
    cpy(src, dst, "container/root/opt/openvpn/ccd/%{client.name}", vars)
  end
  cpy(src, vpn, "container/root/opt/openvpn/dhcp/pool.txt", server_vars)
  cpy(".", vpn, "pki/dh.pem", server_vars)
  cpy(".", vpn, "pki/ca.crt", server_vars)
  cpy(".", vpn, "pki/crl.pem", server_vars)
  cpy(".", vpn, "pki/issued/%{server.name}.crt", server_vars, true)
  cpy(".", vpn, "pki/private/%{server.name}.key", server_vars, true)
  mod(vpn, "pki/private/%{server.name}.key", 0400, server_vars)
end

def generate_client(server, client)
  src = "rb/templates/client"
  dst = "out/clients/%{client.name}"
  cnf = "out/servers/%{client.name}/config/conf"
  opn = "out/servers/%{client.name}/config/ovpn"
  vpn = "out/servers/%{client.name}/container/root/opt/openvpn"

  server_vars = as_sym(flatten(server, path: "server"))
  client_vars = as_sym(flatten(client, path: "client"))

  unless File.exist?("pki/issued/%{client.name}.crt" % client_vars)
    system("ruby", "rb/cert.generate.client.rb", client["name"]) or
      abort("error")
  end

  credentials = {
    "ca.crt.content": File.read("pki/ca.crt").strip,
    "client.issued.crt.content":
      File.read("pki/issued/%{client.name}.crt" % client_vars).strip,
    "client.private.key.content":
      File.read("pki/private/%{client.name}.key" % client_vars).strip
  }

  cpy(src, dst, "deploy.sh", client_vars)
  cpy(src, dst, "container/Dockerfile", client_vars)
  cpy(src, dst, "container/root/opt/entrypoint.sh", client_vars)
  cpy(
    src,
    dst,
    "container/root/opt/openvpn/openvpn.conf",
    {}.merge(server_vars, client_vars)
  )
  cpy(".", vpn, "pki/ca.crt", client_vars)
  cpy(".", vpn, "pki/issued/%{client.name}.crt", client_vars, true)
  cpy(".", vpn, "pki/private/%{client.name}.key", client_vars, true)
  mod(vpn, "pki/private/%{client.name}.key", 0400, client_vars)

  cpy(src, dst, "run.conf.sh", client_vars)
  cpy(src, dst, "run.ovpn.sh", client_vars)
  cpy(
    src,
    dst,
    "config/conf/%{client.name}.conf",
    {}.merge(server_vars, client_vars)
  )
  cpy(".", cnf, "pki/ca.crt", client_vars)
  cpy(".", cnf, "pki/issued/%{client.name}.crt", client_vars, true)
  cpy(".", cnf, "pki/private/%{client.name}.key", client_vars, true)
  mod(cnf, "pki/private/%{client.name}.key", 0400, client_vars)
  cpy(
    src,
    dst,
    "/config/ovpn/%{client.name}.ovpn",
    {}.merge(server_vars, client_vars, credentials)
  )
  mod(dst, "config/ovpn/%{client.name}.ovpn", 0400, client_vars)
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
