# frozen_string_literal: true

require 'kitchen/pulumi'

module Kitchen
  module Pulumi
    # Kitchen::Pulumi::InSpecOptionsMapper maps system configuration attributes
    # to an InSpec options hash.
    class InSpecOptionsMapper
      SYSTEM_ATTRIBUTES_TO_OPTIONS = {
        attrs: :input_file,
        backend_cache: :backend_cache,
        backend: :backend,
        bastion_host: :bastion_host,
        bastion_port: :bastion_port,
        bastion_user: :bastion_user,
        controls: :controls,
        enable_password: :enable_password,
        key_files: :key_files,
        password: :password,
        path: :path,
        port: :port,
        proxy_command: :proxy_command,
        reporter: 'reporter',
        self_signed: :self_signed,
        shell_command: :shell_command,
        shell_options: :shell_options,
        shell: :shell,
        show_progress: :show_progress,
        ssl: :ssl,
        sudo_command: :sudo_command,
        sudo_options: :sudo_options,
        sudo_password: :sudo_password,
        sudo: :sudo,
        user: :user,
        vendor_cache: :vendor_cache,
      }.freeze

      # map populates an InSpec options hash based on the intersection between
      # the system keys and the supported options
      # keys, converting keys from symbols to strings as required by InSpec.
      #
      # @param options [::Hash] the InSpec options hash to be populated.
      # @return [void]
      def map(options:, system:)
        supported = system.lazy.select do |attribute_name, _|
          system_attributes_to_options.key?(attribute_name)
        end

        supported.each do |attribute_name, attribute_value|
          options.store(
            system_attributes_to_options.fetch(attribute_name),
            attribute_value,
          )
        end

        options
      end

      private

      attr_accessor :system_attributes_to_options

      def initialize
        self.system_attributes_to_options = ::Kitchen::Pulumi::InSpecOptionsMapper::SYSTEM_ATTRIBUTES_TO_OPTIONS.dup # rubocop:disable Metrics/LineLength
      end
    end
  end
end
