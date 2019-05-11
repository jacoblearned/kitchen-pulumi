# frozen_string_literal: true

require 'inspec'
require 'kitchen/pulumi/error'
require 'train'

module Kitchen
  module Pulumi
    # InSpec is the class of objects which act as interfaces to InSpec.
    class InSpec
      class << self
        # .logger= sets the logger for all InSpec processes.
        #
        # The logdev of the logger is extended to conform to interface
        # expected by InSpec.
        #
        # @param logger [::Kitchen::Logger] the logger to use.
        # @return [void]
        def logger=(logger)
          logger.logdev.define_singleton_method :filename do
            false
          end

          ::Inspec::Log.logger = logger
        end
      end

      # #exec executes InSpec.
      #
      # @raise [::Kitchen::Pulumi::Error] if executing InSpec fails.
      # @return [self]
      def exec
        @runner.run.tap do |exit_code|
          if exit_code != 0
            raise ::Kitchen::Pulumi::Error, "InSpec exited with #{exit_code}"
          end
        end

        self
      rescue ::ArgumentError, ::RuntimeError, ::Train::UserError => e
        raise ::Kitchen::Pulumi::Error, "Executing InSpec failed\n#{e.message}"
      end

      # #info logs an information message using the InSpec logger.
      #
      # @param message [::String] the message to be logged.
      # @return [self]
      def info(message:)
        ::Inspec::Log.info ::String.new message

        self
      end

      private

      def initialize(options:, profile_locations:)
        @runner = ::Inspec::Runner.new options.merge(
          logger: ::Inspec::Log.logger,
        )
        profile_locations.each do |profile_location|
          @runner.add_target profile_location
        end
      end
    end
  end
end
