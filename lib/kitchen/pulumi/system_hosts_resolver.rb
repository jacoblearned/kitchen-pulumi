# frozen_string_literal: true

require 'kitchen/pulumi'
require 'kitchen/pulumi/error'

module Kitchen
  module Pulumi
    # SystemHostsResolver is the class of objects which resolve for systems the
    # hosts which are contained in outputs.
    class SystemHostsResolver
      # #resolve resolves the hosts.
      #
      # @param hosts_output [::String] the name of the Pulumi output which has
      #   a value of hosts for the system.
      # @param system [::Kitchen::Pulumi::System] the system.
      # @raise [::Kitchen::Pulumi::Error] if the fetching the value of the
      #   output fails.
      def resolve(hosts_output:, system:)
        system.add_hosts hosts: @outputs.fetch(hosts_output).fetch('value')
      rescue ::KeyError => e
        raise ::Kitchen::Pulumi::Error, "Resolving hosts failed\n#{e}"
      end

      private

      # #initialize prepares the instance to be used.
      #
      # @param outputs [#to_hash] the outputs of the Pulumi stack under test.
      def initialize(outputs:)
        @outputs = Hash[outputs]
      end
    end
  end
end
