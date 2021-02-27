# frozen_string_literal: true

require 'kitchen/pulumi'
require 'kitchen/pulumi/error'

module Kitchen
  module Pulumi
    # SystemInputssResolver is the class for resolving Pulumi stack inputs and
    # outputs to provide them as Inspec Inputs.
    class SystemInputsResolver
      # #resolve resolves the inputs.
      #
      # @raise [::Kitchen::Pulumi::Error] if the fetching the value of the
      #   output fails.
      def resolve
        @system.add_inputs(inputs: @pulumi_inputs.merge(@pulumi_outputs))
        self
      rescue ::KeyError => e
        raise ::Kitchen::Pulumi::Error, "Resolving inputs failed\n#{e}"
      end

      private

      # #initialize prepares the instance to be used.
      #
      # @param pulumi_inputs [#to_hash] the config inputs provided to a Pulumi stack
      # @param pulumi_outputs [#to_hash] the outputs of the Pulumi stack under test.
      # @param system [::Kitchen::Pulumi::System] the system.
      def initialize(pulumi_inputs:, pulumi_outputs:, system:)
        @system = system
        @pulumi_inputs = pulumi_inputs.transform_values do |value|
          value.fetch('value', nil)
        end
        @pulumi_inputs.merge!(@pulumi_inputs.transform_keys { |key| "input_#{key}" })

        @pulumi_outputs = pulumi_outputs.to_h.map do |key, value|
          [key, value]
        end.to_h
        @pulumi_outputs.merge!(@pulumi_outputs.transform_keys { |key| "output_#{key}" })
      rescue ::KeyError => e
        raise ::Kitchen::Pulumi::Error, "System input resolution failed\n#{e}"
      end
    end
  end
end
