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
      module Input
        class << self
          def run(directory:, stack:, conf_file:, logger:)
            cmd = "config -C #{directory} -s #{stack} #{conf_file} -j"

            ::Kitchen::Pulumi::ShellOut.run(cmd: cmd, logger: logger) do |stdout:|
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
end
