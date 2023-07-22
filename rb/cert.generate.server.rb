#!/usr/bin/env ruby

name = ARGV.first

abort("name required") if not name or not name.length

system("easyrsa", "--batch", "gen-req", name, "nopass") or abort("error")
system("easyrsa", "--batch", "sign-req", "server", name) or abort("error")
system("chmod", "0400", "./pki/private/#{name}.key") or abort("error")

puts("done")
