#!/usr/bin/env ruby

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
