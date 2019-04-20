# frozen_string_literal: true

require 'dry-validation'
require 'kitchen/pulumi/config_schemas'

module Kitchen
  module Pulumi
    ConfigSchemas::StackSettingsHash = ::Dry::Validation.Schema do
      configure do
        config.messages_file = "#{__dir__}/error_messages.yml"

        def stack_settings_hash?(value)
          return false unless value.is_a?(Hash)

          value.all? { |_, nested_hash| nested_hash.is_a?(Hash) }
        end
      end

      required(:value).maybe(:hash?, :stack_settings_hash?)
    end
  end
end
