# frozen_string_literal: true

require 'dry-validation'
require 'kitchen/pulumi/config_schemas'

module Kitchen
  module Pulumi
    ConfigSchemas::ConfigEvolutionArray = ::Dry::Validation.Schema do
      configure do
        config.messages_file = "#{__dir__}/error_messages.yml"

        def config_evolution_items_valid_types?(value)
          return false unless value.is_a?(Hash)

          config_file = value.fetch(:config_file, '')
          conf = value.fetch(:config, {})
          secrets = value.fetch(:secrets, {})

          config_file.is_a?(String) && conf.is_a?(Hash) && secrets.is_a?(Hash)
        end

        def config_evolution_array_item_valid?(value)
          c_file = value.fetch(:config_file, '')
          config = value.fetch(:config, {})
          secrets = value.fetch(:secrets, {})

          c_file_ok = c_file.empty? || File.file?(File.expand_path(c_file))
          config_valid = config.all? { |_, nested| nested.is_a?(Hash) }
          secrets_valid = secrets.all? { |_, nested| nested.is_a?(Hash) }
          c_file_ok && config_valid && secrets_valid
        end
      end

      required(:value).each(
        :config_evolution_items_valid_types?,
        :config_evolution_array_item_valid?,
      )
    end
  end
end
