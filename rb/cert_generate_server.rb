#!/usr/bin/env ruby

def cert_generate_server(pki_path: "pki")
  pki = "#{pki_path}"
  name = ARGV.first

  abort("name required") if not name or not name.length

  system("easyrsa", "--batch", "--pki-dir=#{pki}", "gen-req", name, "nopass") or
    abort("error")
  system(
    "easyrsa",
    "--batch",
    "--pki-dir=#{pki}",
    "sign-req",
    "server",
    name
  ) or abort("error")
  system("chmod", "0400", "./#{pki}/private/#{name}.key") or abort("error")

  puts("done")
end

cert_generate_server
