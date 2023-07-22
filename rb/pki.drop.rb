#!/usr/bin/env ruby

File.exist?("pki") or abort("pki not exist")

system("rm", "-rfv", "pki") or abort("error")

puts("done")
