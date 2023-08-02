def easyrsa_gen_req(pki, name)
  cmd = ["easyrsa", "--batch", "--pki-dir=#{pki}", "gen-req", name, "nopass"]
  IO.popen(cmd) { |io| io.each { |line| print line } }
  abort("cert request error") unless $?.exitstatus == 0
end

def easyrsa_sign_req(pki, name, type)
  cmd = ["easyrsa", "--batch", "--pki-dir=#{pki}", "sign-req", type, name]
  IO.popen(cmd) { |io| io.each { |line| print line } }
  abort("cert sign error") unless $?.exitstatus == 0
end

def easyrsa_revoke(pki, name)
  cmd = ["easyrsa", "--batch", "--pki-dir=#{pki}", "revoke", name]
  IO.popen(cmd) { |io| io.each { |line| print line } }
  abort("revoke cert error") unless $?.exitstatus == 0
end

def easyrsa_gen_crl(pki)
  cmd = ["easyrsa", "--batch", "--pki-dir=#{pki}", "gen-crl"]
  IO.popen(cmd) { |io| io.each { |line| print line } }
  abort("revoke list error") unless $?.exitstatus == 0
end

def easyrsa_init_pki(pki)
  cmd = ["easyrsa", "--batch", "--pki-dir=#{pki}", "init-pki"]
  IO.popen(cmd) { |io| io.each { |line| print line } }
  abort("revoke list error") unless $?.exitstatus == 0
end

def easyrsa_build_ca(pki)
  cmd = ["easyrsa", "--batch", "--pki-dir=#{pki}", "build-ca", "nopass"]
  IO.popen(cmd) { |io| io.each { |line| print line } }
  abort("revoke list error") unless $?.exitstatus == 0
end

def easyrsa_gen_dh(pki)
  cmd = ["easyrsa", "--batch", "--pki-dir=#{pki}", "gen-dh"]
  IO.popen(cmd) { |io| io.each { |line| print line } }
  abort("revoke list error") unless $?.exitstatus == 0
end
