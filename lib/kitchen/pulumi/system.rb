# frozen_string_literal: true

require 'kitchen/pulumi/error'
require 'kitchen/pulumi/inspec_with_hosts'
require 'kitchen/pulumi/inspec_without_hosts'
require 'kitchen/pulumi/system_attrs_resolver'
require 'kitchen/pulumi/system_hosts_resolver'

module Kitchen
  module Pulumi
    # System is the class of objects which are verified by the Pulumi Verifier.
    class System
      # #add_attrs adds attributes to the system.
      #
      # @param attrs [#to_hash] the attributes to be added.
      # @return [self]
      def add_attrs(attrs:)
        @attributes = @attributes.merge Hash attrs

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
      # @param inputs [::Hash] the Pulumi input values to be utilized as
      #   InSpec profile attributes.
      # @param inspec_options [::Hash] the options to be passed to InSpec.
      # @param outputs [::Hash] the Pulumi output values to be utilized as
      #   InSpec profile attributes.
      # @return [self]
      def verify(inputs:, inspec_options:, outputs:)
        resolve inputs: inputs, outputs: outputs
        execute_inspec options: inspec_options

        self
      rescue StandardError => e
        raise ::Kitchen::Pulumi::Error, "#{self}: #{e.message}"
      end

      private

      def execute_inspec(options:)
        inspec.new(
          options: options_with_attributes(options: options),
          profile_locations: @mapping.fetch(:profile_locations),
        ).exec(system: self)
      end

      def initialize(mapping:)
        @attributes = {}
        @attrs_outputs = mapping.fetch :attrs_outputs do
          {}
        end
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

      def options_with_attributes(options:)
        options.merge attributes: @attributes
      end

      def resolve(inputs:, outputs:)
        resolve_attrs inputs: inputs, outputs: outputs
        resolve_hosts outputs: outputs
      end

      def resolve_attrs(inputs:, outputs:)
        ::Kitchen::Pulumi::SystemAttrsResolver.new(
          inputs: inputs, outputs: outputs,
        ).resolve(
          attrs_outputs_keys: @attrs_outputs.keys,
          attrs_outputs_values: @attrs_outputs.values,
          system: self,
        )

        self
      end

      def resolve_hosts(outputs:)
        return self unless @mapping.key? :hosts_output

        ::Kitchen::Pulumi::SystemHostsResolver.new(outputs: outputs).resolve(
          hosts_output: @mapping.fetch(:hosts_output),
          system: self,
        )

        self
      end
    end
  end
end
