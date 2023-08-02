require "FileUtils"
require_relative "./easyrsa"

def cert_create_server(env, name)
  pki = env[:pki]
  easyrsa_gen_req(pki, name)
  easyrsa_sign_req(pki, name, "server")
end

def cert_create_client(env, name)
  pki = env[:pki]
  easyrsa_gen_req(pki, name)
  easyrsa_sign_req(pki, name, "client")
  FileUtils.chmod(0600, "#{pki}/private/#{name}.key")
end

def cert_revoke(env, name)
  pki = env[:pki]
  easyrsa_revoke(pki, name)
  easyrsa_gen_crl(pki)
end

def cert_update(env)
  pki = env[:pki]
  easyrsa_gen_crl(pki)
end

def cert_names(env)
  pki = env[:pki]
  Dir.glob("#{pki}/issued/*crt").map { |path| File.basename(path, ".*") }
end
