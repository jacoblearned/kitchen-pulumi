# frozen_string_literal: true

require 'kitchen/pulumi'
require 'kitchen/pulumi/error'

module Kitchen
  module Pulumi
    # SystemAttrsResolver is the class of objects which resolve for systems the
    # attrs which are contained in outputs.
    class SystemAttrsResolver
      # #resolve resolves the attrs.
      #
      # @param attrs_outputs_keys [::Array<::String>] the names of the InSpec
      #   attributes.
      # @param attrs_outputs_values [::Array<::String>] the names of the Pulumi
      #   outputs.
      # @param system [::Kitchen::Pulumi::System] the system.
      # @raise [::Kitchen::Pulumi::Error] if the fetching the value of the
      #   output fails.
      def resolve(attrs_outputs_keys:, attrs_outputs_values:, system:)
        system.add_attrs(attrs: @inputs.merge(
          @outputs.merge(
            attrs_outputs_keys.lazy.map(&:to_s).zip(
              @outputs.fetch_values(*attrs_outputs_values),
            ).to_h,
          ),
        ))

        self
      rescue ::KeyError => e
        raise ::Kitchen::Pulumi::Error, "Resolving attrs failed\n#{e}"
      end

      private

      # #initialize prepares the instance to be used.
      #
      # @param inputs [#to_hash] the config inputs provided to a stack
      # @param outputs [#to_hash] the outputs of the Pulumi stack under test.
      def initialize(inputs:, outputs:)
        @inputs = inputs.map do |key, value|
          [key, value.fetch('value', nil)]
        end.to_h
        @inputs.merge!(@inputs.map do |key, value|
          ["input_#{key}", value]
        end.to_h)

        @outputs = Hash[outputs].map do |key, value|
          [key, value]
        end.to_h
        @outputs.merge!(@outputs.map do |key, value|
          ["output_#{key}", value]
        end.to_h)
      rescue ::KeyError => e
        raise ::Kitchen::Pulumi::Error, "System attrs resolution failed\n#{e}"
      end
    end
  end
end
