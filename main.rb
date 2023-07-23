#!/usr/bin/env ruby

def main()
  command_name = ARGV.first
  commands =
    Dir
      .glob("rb/*.rb")
      .map { |path| [File.basename(path, (File.extname path)), path] }
      .to_h

  command_path = commands[command_name]
  unless command_path
    abort("command_name invalid, options: \n#{commands.keys.join("\n")}")
  end

  system("ruby", command_path, *ARGV.drop(1))
end

main
