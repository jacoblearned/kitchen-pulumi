# frozen_string_literal: true

require 'json'
require 'kitchen'
require 'kitchen/pulumi/command'
require 'kitchen/pulumi/error'
require 'kitchen/pulumi/shell_out'

module Kitchen
  module Pulumi
    module Command
      # Class used to fetch stack outputs via '$ pulumi stack output --json'
      module Output
        class << self
          def run(directory:, stack:, logger:)
            cmd = "stack -C #{directory} -s #{stack} output -j"

            ::Kitchen::Pulumi::ShellOut.run(cmd: cmd, logger: logger) do |stdout:|
              yield outputs: ::Kitchen::Util.stringified_hash(
                ::JSON.parse(stdout),
              )
            end
          rescue ::JSON::ParserError => e
            raise(
              ::Kitchen::Pulumi::Error,
              "Parsing Pulumi stack output as JSON failed: #{e.message}",
            )
          end
        end
      end
    end
  end
end
