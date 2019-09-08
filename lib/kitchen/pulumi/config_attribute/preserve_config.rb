# frozen_string_literal: true

require 'kitchen/pulumi'
require 'kitchen/pulumi/config_schemas/boolean'
require 'kitchen/pulumi/config_attribute_cacher'
require 'kitchen/pulumi/config_attribute_definer'

module Kitchen
  module Pulumi
    module ConfigAttribute
      # Attribute used to determine if the stack config should be
      # preserved after stack is removed with `pulumi stack rm`
      # during destroy.
      module PreserveConfig
        def self.included(plugin_class)
          definer = ConfigAttributeDefiner.new(
            attribute: self,
            schema: ConfigSchemas::Boolean,
          )
          definer.define(plugin_class: plugin_class)
        end

        def self.to_sym
          :preserve_config
        end

        extend ConfigAttributeCacher

        def config_preserve_config_default_value
          false
        end
      end
    end
  end
end
