# frozen_string_literal: true

require 'kitchen/pulumi'

module Kitchen
  module Pulumi
    # This class defines attributes consumed from .kitchen.yml and
    # used in the Test Kitchen plugins.
    class ConfigAttributeDefiner
      def initialize(attribute:, schema:)
        @attribute = attribute.to_sym
        @schema = schema
      end

      def define(plugin_class:)
        plugin_class.required_config(@attribute) do |_attribute, value, _plugin|
          schema_messages = @schema.call(value: value).messages
          process_schema_messages(messages: schema_messages,
                                  plugin_class: plugin_class)
        end

        plugin_class.default_config(@attribute) do |plugin|
          plugin.send "config_#{@attribute}_default_value"
        end
      end

      private

      def process_schema_messages(messages:, plugin_class:)
        return true if messages.empty?
        raise(
          ::Kitchen::UserError,
          "#{plugin_class} config: #{@attribute} #{messages}",
        )
      end
    end
  end
end
