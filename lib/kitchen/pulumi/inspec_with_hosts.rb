# frozen_string_literal: true

require 'kitchen'
require 'kitchen/pulumi/error'
require 'kitchen/pulumi/inspec'

module Kitchen
  module Pulumi
    # InSpec instances act as interfaces to the InSpec gem.
    class InSpecWithHosts
      # exec executes the InSpec controls of an InSpec profile.
      #
      # @raise [::Kitchen::Pulumi::Error] if the execution of the InSpec
      #  controls fails.
      # @return [void]
      def exec(system:)
        system.each_host do |host:|
          ::Kitchen::Pulumi::InSpec
            .new(
              options: options.merge(host: host),
              profile_locations: profile_locations,
            )
            .info(message: "#{system}: Verifying host #{host}").exec
        end
      end

      private

      attr_accessor :options, :profile_locations

      # @param options [::Hash] options for execution.
      # @param profile_locations [::Array<::String>] the locations of the
      #   InSpec profiles which contain the controls to be executed.
      def initialize(options:, profile_locations:)
        self.options = options
        self.profile_locations = profile_locations
      end
    end
  end
end
