# frozen_string_literal: true

require 'tempfile'

# Global kitchen module
module Kitchen
  # Namespace for Kitchen-Pulumi logic
  # @author Jacob Learned
  module Pulumi
    # Copies the contents of the given config file to a temporary file and yields the
    #   path of the temporary file to the block given
    #
    # @param config_file [String] the path to the config file to copy into the temp file
    #
    # for block {|temp_conf| ... }
    # @yield [temp_conf] gives the path to the temporary config file
    def self.with_temp_conf(config_file = '')
      temp_conf = Tempfile.new(['kitchen-pulumi', '.yaml'])

      if config_file.empty?
        yield('') if block_given?
      else
        begin
          IO.copy_stream(config_file, temp_conf.path)
          yield(temp_conf.path) if block_given?
        ensure
          temp_conf.close
          temp_conf.unlink
        end
      end
    end
  end
end
