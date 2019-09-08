# frozen_string_literal: true

# Global kitchen module
module Kitchen
  # Namespace for Kitchen-Pulumi logic
  module Pulumi
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
