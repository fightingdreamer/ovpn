#!/usr/bin/env ruby

def cert_revoke()
  name = ARGV.first

  abort("name required") if not name or not name.length

  # remove certificate
  system("easyrsa", "--batch", "revoke", name) or abort("error")

  # update revoke list
  system("easyrsa", "gen-crl") or abort("error")

  puts("done")
end

cert_revoke
