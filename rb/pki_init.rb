#!/usr/bin/env ruby

def pki_init()
  raise "pki already exist" if File.exist?("pki")

  # pki
  system("easyrsa", "init-pki") or abort("error")

  # ca
  system("easyrsa", "--batch", "build-ca", "nopass") or abort("error")

  # dh params
  system("easyrsa", "gen-dh") or abort("error")

  # create revoke list
  system("easyrsa", "gen-crl") or abort("error")

  puts("done")
end

pki_init
