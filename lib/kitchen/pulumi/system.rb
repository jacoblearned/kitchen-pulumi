# frozen_string_literal: true

require 'kitchen/pulumi/error'
require 'kitchen/pulumi/inspec_with_hosts'
require 'kitchen/pulumi/inspec_without_hosts'
require 'kitchen/pulumi/system_inputs_resolver'
require 'kitchen/pulumi/system_hosts_resolver'

module Kitchen
  module Pulumi
    # System is the class of objects which are verified by the Pulumi Verifier.
    class System
      # #add_inputs adds Inspec Inputs to the system.
      #
      # @param inputs [#to_hash] the inputs to be added.
      # @return [self]
      def add_inputs(inputs:)
        @inputs = @inputs.merge Hash inputs

        self
      end

      # #add_hosts adds hosts to the system.
      #
      # @param hosts [#to_arr,#to_a] the hosts to be added.
      # @return [self]
      def add_hosts(hosts:)
        @hosts += Array hosts

        self
      end

      # #each_host enumerates each host of the system.
      #
      # @yieldparam host [::String] the next host.
      # @return [self]
      def each_host
        @hosts.each do |host|
          yield host: host
        end

        self
      end

      # #to_s returns a string representation of the system.
      #
      # @return [::String] the name of the system.
      def to_s
        @mapping.fetch :name
      end

      # #verify verifies the system by executing InSpec.
      #
      # @param pulumi_inputs [::Hash] the Pulumi input values to be utilized as
      #   InSpec profile Input.
      # @param pulumi_outputs [::Hash] the Pulumi output values to be utilized as
      #   InSpec profile Input.
      # @param inspec_options [::Hash] the options to be passed to InSpec.
      # @return [self]
      def verify(pulumi_inputs:, pulumi_outputs:, inspec_options:)
        resolve(pulumi_inputs: pulumi_inputs, pulumi_outputs: pulumi_outputs)
        execute_inspec(options: inspec_options)

        self
      rescue StandardError => e
        raise ::Kitchen::Pulumi::Error, "#{self}: #{e.message}"
      end

      private

      def execute_inspec(options:)
        inspec.new(
          options: options_with_inputs(options: options),
          profile_locations: @mapping.fetch(:profile_locations),
        ).exec(system: self)
      end

      def initialize(mapping:)
        @inputs = {}
        @hosts = mapping.fetch :hosts do
          []
        end
        @mapping = mapping
      end

      def inspec
        if @hosts.empty?
          ::Kitchen::Pulumi::InSpecWithoutHosts
        else
          ::Kitchen::Pulumi::InSpecWithHosts
        end
      end

      def options_with_inputs(options:)
        options.merge(inputs: @inputs)
      end

      def resolve(pulumi_inputs:, pulumi_outputs:)
        resolve_inputs(pulumi_inputs: pulumi_inputs, pulumi_outputs: pulumi_outputs)
        resolve_hosts(pulumi_outputs: pulumi_outputs)
      end

      def resolve_inputs(pulumi_inputs:, pulumi_outputs:)
        ::Kitchen::Pulumi::SystemInputsResolver.new(
          pulumi_inputs: pulumi_inputs, pulumi_outputs: pulumi_outputs, system: self,
        ).resolve

        self
      end

      def resolve_hosts(pulumi_outputs:)
        return self unless @mapping.key?(:hosts_output)

        ::Kitchen::Pulumi::SystemHostsResolver.new(outputs: pulumi_outputs).resolve(
          hosts_output: @mapping.fetch(:hosts_output),
          system: self,
        )

        self
      end
    end
  end
end
