#!/usr/bin/env ruby

require_relative "src/pki"
require_relative "src/cert"
require_relative "src/config"

def main()
  env = { pki: "pki", tpl: "tpl", out: "out", cfg: "config.json" }
  commands = %w[
    pki_init
    pki_drop
    cert_create_server
    cert_create_client
    cert_revoke
    cert_update
    config_init
    config_sync
  ]

  command_name = ARGV.first
  command_args = ARGV.drop(1)
  command = commands.filter { |command| command == command_name }.first

  abort("`command` invalid, options: \n#{commands.join("\n")}") if command.nil?
  send(command, env, *command_args)

  puts "done"
end

main
