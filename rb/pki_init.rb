#!/usr/bin/env ruby

def pki_init(pki_path: "pki")
  pki = "#{pki_path}"
  raise "#{pki} already exist" if File.exist?(pki)

  # pki
  system("easyrsa", "--batch", "--pki-dir=#{pki}", "init-pki") or abort("error")

  # ca
  system("easyrsa", "--batch", "--pki-dir=#{pki}", "build-ca", "nopass") or
    abort("error")

  # dh params
  system("easyrsa", "--batch", "--pki-dir=#{pki}", "gen-dh") or abort("error")

  # create revoke list
  system("easyrsa", "--batch", "--pki-dir=#{pki}", "gen-crl") or abort("error")

  puts("done")
end

pki_init
