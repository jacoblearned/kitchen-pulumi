# frozen_string_literal: true

require 'kitchen/pulumi'
require 'kitchen/pulumi/config_attribute_definer'

module Kitchen
  module Pulumi
    class FilePathConfigAttributeDefiner
      def initialize(attribute:, schema:)
        @attribute = attribute
        @definer = ConfigAttributeDefiner.new(
          attribute: attribute,
          schema: schema,
        )
      end

      # Defines the config attribute and then expands the file path
      def define(plugin_class: plugin)
        @definer.define(plugin_class: plugin_class)
        plugin_class.expand_path_for(@attribute.to_sym)
      end
    end
  end
end
