#!/usr/bin/env ruby

name = ARGV.first

abort("name required") if not name or not name.length

# remove certificate
system("easyrsa", "revoke", name) or abort("error")

# update revoke list
system("easyrsa", "gen-crl") or abort("error")

puts("done")
