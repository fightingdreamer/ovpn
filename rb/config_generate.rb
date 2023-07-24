#!/usr/bin/env ruby

require "set"
require "JSON"
require "OpenSSL"
require "FileUtils"

def server_files(
  cfg_server,
  cfg_clients,
  pki_path: "pki",
  tem_path: "rb/templates",
  out_path: "out"
)
  server_name = cfg_server[:server_name]

  pki = "#{pki_path}"
  tem = "#{tem_path}/server"
  out = "#{out_path}/servers/#{server_name}"

  return [
    # ./conf
    { src: "#{tem}/run_conf.sh", dst: "#{out}/run_conf.sh", cfg: cfg_server },
    {
      src: "#{tem}/conf/%{server_name}.conf",
      dst: "#{out}/conf/#{server_name}.conf",
      cfg: cfg_server
    },
    { src: "#{tem}/conf/dhcp/pool.txt", dst: "#{out}/conf/dhcp/pool.txt" },
    *cfg_clients.map do |cfg_client|
      client_name = cfg_client[:client_name]
      (
        {
          src: "#{tem}/conf/ccd/%{client_name}",
          dst: "#{out}/conf/ccd/#{client_name}",
          cfg: {}.merge(cfg_server, cfg_client)
        }
      )
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
      mod: 0600
    },
    # container
    {
      src: "#{tem}/run_container.sh",
      dst: "#{out}/run_container.sh",
      cfg: cfg_server
    },
    { src: "#{tem}/container/Dockerfile", dst: "#{out}/container/Dockerfile" },
    {
      src: "#{tem}/container/root/opt/entrypoint.sh",
      dst: "#{out}/container/root/opt/entrypoint.sh"
    },
    {
      src: "#{tem}/container/root/opt/openvpn/openvpn.conf",
      dst: "#{out}/container/root/opt/openvpn/openvpn.conf",
      cfg: cfg_server
    },
    {
      src: "#{tem}/container/root/opt/openvpn/dhcp/pool.txt",
      dst: "#{out}/container/root/opt/openvpn/dhcp/pool.txt"
    },
    *cfg_clients.map do |cfg_client|
      client_name = cfg_client[:client_name]
      (
        {
          src: "#{tem}/container/root/opt/openvpn/ccd/%{client_name}",
          dst: "#{out}/container/root/opt/openvpn/ccd/#{client_name}",
          cfg: {}.merge(cfg_server, cfg_client)
        }
      )
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
      mod: 0600
    }
  ]
end

def client_files(
  cfg_server,
  cfg_client,
  cfg_client_pki,
  pki_path: "pki",
  tem_path: "rb/templates",
  out_path: "out"
)
  client_name = cfg_client[:client_name]

  pki = "#{pki_path}"
  tem = "#{tem_path}/client"
  out = "#{out_path}/clients/#{client_name}"

  return [
    # ./conf
    { src: "#{tem}/run_conf.sh", dst: "#{out}/run_conf.sh", cfg: cfg_client },
    {
      src: "#{tem}/conf/%{client_name}.conf",
      dst: "#{out}/conf/#{client_name}.conf",
      cfg: {}.merge(cfg_server, cfg_client)
    },
    { src: "#{pki}/ca.crt", dst: "#{out}/conf/pki/ca.crt" },
    {
      src: "#{pki}/issued/#{client_name}.crt",
      dst: "#{out}/conf/pki/issued/#{client_name}.crt"
    },
    {
      src: "#{pki}/private/#{client_name}.key",
      dst: "#{out}/conf/pki/private/#{client_name}.key",
      mod: 0600
    },
    # ./ovpn
    { src: "#{tem}/run_ovpn.sh", dst: "#{out}/run_ovpn.sh", cfg: cfg_client },
    {
      src: "#{tem}/ovpn/%{client_name}.ovpn",
      dst: "#{out}/ovpn/#{client_name}.ovpn",
      cfg: {}.merge(cfg_server, cfg_client, cfg_client_pki),
      mod: 0600
    },
    # ./container
    {
      src: "#{tem}/run_container.sh",
      dst: "#{out}/run_container.sh",
      cfg: cfg_client
    },
    { src: "#{tem}/container/Dockerfile", dst: "#{out}/container/Dockerfile" },
    {
      src: "#{tem}/container/root/opt/entrypoint.sh",
      dst: "#{out}/container/root/opt/entrypoint.sh"
    },
    {
      src: "#{tem}/container/root/opt/openvpn/openvpn.conf",
      dst: "#{out}/container/root/opt/openvpn/openvpn.conf",
      cfg: {}.merge(cfg_server, cfg_client)
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
      mod: 0600
    }
  ]
end

def flatten_hash(value, path = nil)
  {}.merge *value.map { |k, v| flatten(v, [path, k].compact.join("_").to_sym) }
end

def flatten_array(value, path)
  { path.to_sym => value.map { |v| flatten(v, path) } }
end

def flatten_other(value, path)
  { path.to_sym => value }
end

def flatten(value, path = nil)
  return flatten_hash(value, path) if value.is_a?(Hash)
  return flatten_array(value, path) if value.is_a?(Array)
  flatten_other(value, path)
end

def get_client_pki_as_cfg(cfg_client, pki_path: "pki")
  pki = "#{pki_path}"
  client_name = cfg_client[:client_name]
  {
    "ca.crt": File.read("#{pki}/ca.crt").strip,
    "client_issued.crt": File.read("#{pki}/issued/#{client_name}.crt").strip,
    "client_private.key": File.read("#{pki}/private/#{client_name}.key").strip
  }
end

def drop_unused_files(paths)
  paths
    .select { |path| File.file?(path) }
    .each do |path|
      File.delete(path)
      p "deleted #{path}"
    end
end

def drop_unused_dirs(paths)
  paths
    .select { |path| File.directory?(path) }
    .sort { |a, b| b.split("/").length <=> a.split("/").length }
    .each do |path|
      next if Dir.children(path).length != 0
      Dir.rmdir(path)
      p "deleted #{path}"
    end
end

def config_generate(
  cfg_path: "config.json",
  pki_path: "pki",
  tem_path: "rb/templates",
  out_path: "out"
)
  pki = "#{pki_path}"
  out = "#{out_path}"
  raw = JSON.load_file(cfg_path)

  server_names = [raw["server"]["name"]].to_set
  client_names = raw["clients"].map { |client| client["name"] }.to_set

  cert_names =
    Dir
      .glob("#{pki}/issued/*crt")
      .map { |path| File.basename(path, File.extname(path)) }
      .to_set

  for cert_name in cert_names - (server_names + client_names)
    system("ruby", "rb/cert_revoke.rb", cert_name)
  end

  for server_name in server_names - cert_names
    system("ruby", "rb/cert_generate_server.rb", server_name)
  end

  for client_name in client_names - cert_names
    system("ruby", "rb/cert_generate_client.rb", client_name)
  end

  cfg_server = flatten_hash(raw["server"], :server)
  cfg_clients = raw["clients"].map { |client| flatten_hash(client, :client) }

  server_ops =
    server_files(
      cfg_server,
      cfg_clients,
      pki_path: pki_path,
      tem_path: tem_path,
      out_path: out_path
    )
  client_ops =
    cfg_clients.map do |cfg_client|
      client_files(
        cfg_server,
        cfg_client,
        get_client_pki_as_cfg(cfg_client),
        pki_path: pki_path,
        tem_path: tem_path,
        out_path: out_path
      )
    end

  ops = [*server_ops, *client_ops.flatten]
  new = ops.map { |op| op[:dst] }.to_set
  old = Dir.glob("#{out}/**/*").to_set

  for op in ops
    src = op[:src]
    dst = op[:dst]
    cfg = op[:cfg]
    mod = op[:mod]
    src_content = File.read(src)
    dst_content = src_content % cfg
    unless File.exist?(dst)
      dir = File.dirname(dst)
      FileUtils.mkdir_p(dir)
      File.write(dst, dst_content)
      p "created #{dst}"
    end
    unless File.read(dst) == dst_content
      File.write(dst, dst_content)
      p "updated #{dst}"
    end
    unless mod.nil? or File.stat(dst).mode & 0777 == mod
      FileUtils.chmod(mod, dst)
      p "updated #{dst}"
      next
    end
  end

  drop_unused_files(old - new)
  drop_unused_dirs(old)
end

config_generate()
