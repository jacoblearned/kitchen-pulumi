# frozen_string_literal: true

require 'kitchen/pulumi/inspec'

module Kitchen
  module Pulumi
    # InSpec instances act as interfaces to the InSpec gem.
    class InSpecWithoutHosts
      # exec executes the InSpec controls of an InSpec profile.
      #
      # @raise [::Kitchen::Pulumi::Error] if the execution of the InSpec
      #   controls fails.
      # @return [void]
      def exec(system:)
        ::Kitchen::Pulumi::InSpec
          .new(options: options, profile_locations: profile_locations)
          .info(message: "#{system}: Verifying")
          .exec
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
