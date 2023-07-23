#!/usr/bin/env ruby

def cert_revoke(pki_path: "pki")
  pki = "#{pki_path}"
  name = ARGV.first

  abort("name required") if not name or not name.length

  # remove certificate
  system("easyrsa", "--batch", "--pki-dir=#{pki}", "revoke", name) or
    abort("error")

  # update revoke list
  system("easyrsa", "--batch", "--pki-dir=#{pki}", "gen-crl") or abort("error")

  puts("done")
end

cert_revoke
