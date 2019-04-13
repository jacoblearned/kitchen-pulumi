# frozen_string_literal: true

require 'kitchen/pulumi'
require 'kitchen/pulumi/config_schemas/string'
require 'kitchen/pulumi/config_attribute_cacher'
require 'kitchen/pulumi/config_attribute_definer'

module Kitchen
  module Pulumi
    module ConfigAttribute
      # Attribute used to specify the stack to use for a specific instance
      module Stack
        def self.included(plugin_class)
          definer = ConfigAttributeDefiner.new(
            attribute: self,
            schema: ConfigSchemas::String,
          )
          definer.define(plugin_class: plugin_class)
        end

        def self.to_sym
          :stack
        end

        extend ConfigAttributeCacher

        def config_stack_default_value
          ''
        end
      end
    end
  end
end
