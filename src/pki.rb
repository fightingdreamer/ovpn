require_relative "./easyrsa"

def pki_init(env)
  pki = env[:pki]
  abort("pki already exist") if File.exist?(pki)
  easyrsa_init_pki(pki)
  easyrsa_build_ca(pki)
  FileUtils.chmod(0600, "#{pki}/private/ca.key")
  easyrsa_gen_dh(pki)
end

def pki_drop(env)
  pki = env[:pki]
  abort("pki not exist") unless File.exist?(pki)
  FileUtils.rm_r([pki])
end
