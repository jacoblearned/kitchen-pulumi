# frozen_string_literal: true

require 'json'
require 'kitchen'
require 'kitchen/pulumi/command'
require 'kitchen/pulumi/error'
require 'kitchen/pulumi/shell_out'

module Kitchen
  module Pulumi
    module Command
      # Class used to fetch resolved stack inputs via '$ pulumi config --json'
      class Input
        def run(directory:, stack:, conf_file:)
          cmd = "config -C #{directory} -s #{stack} #{conf_file} -j"

          ::Kitchen::Pulumi::ShellOut.run(command: cmd) do |stdout:|
            yield inputs: ::Kitchen::Util.stringified_hash(
              ::JSON.parse(stdout),
            )
          end
        rescue ::JSON::ParserError => e
          raise(
            ::Kitchen::Pulumi::Error,
            "Parsing resolved stack config as JSON failed: #{e.message}",
          )
        end
      end
    end
  end
end
