# frozen_string_literal: true

require 'kitchen/pulumi'
require 'kitchen/pulumi/error'
require 'mixlib/shellout'

module Kitchen
  module Pulumi
    # Module orchestrating calls to the Pulumi CLI
    module ShellOut
      # Shells out to the Pulumi CLI
      def self.run(cmd:, duration: 7200, logger:, &block)
        block ||= ->(stdout) { stdout }
        shell_out(command: cmd, duration: duration, logger: logger, &block)
      rescue ::Errno::EACCES, ::Errno::ENOENT,
             ::Mixlib::ShellOut::InvalidCommandOption,
             ::Mixlib::ShellOut::CommandTimeout,
             ::Mixlib::ShellOut::ShellCommandFailed => error
        raise(::Kitchen::Pulumi::Error, "Error: #{error.message}")
      end

      def self.shell_out(command:, duration: 7200, logger:)
        shell_out = ::Mixlib::ShellOut.new(
          "pulumi #{command}",
          live_stream: logger,
          timeout: duration,
        )

        logger.warn("Running #{shell_out.command}")

        shell_out.run_command
        shell_out.error!
        yield(stdout: shell_out.stdout)
      end
    end
  end
end
