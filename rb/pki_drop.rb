#!/usr/bin/env ruby

def pki_drop(pki_path: "pki")
  pki = "#{pki_path}"
  File.exist?(pki) or abort("#{pki} not exist")

  system("rm", "-rfv", pki) or abort("error")

  puts("done")
end

pki_drop
