# frozen_string_literal: true

require 'kitchen'
require 'kitchen/pulumi'
require 'kitchen/pulumi/config_schemas/boolean'
require 'kitchen/pulumi/config_attribute_cacher'
require 'kitchen/pulumi/config_attribute_definer'

module Kitchen
  module Pulumi
    module ConfigAttribute
      # Attribute to toggle colored output from systems invoked by the plugin
      module Color
        def self.included(plugin_class)
          definer = ConfigAttributeDefiner.new(
            attribute: self,
            schema: ConfigSchemas::Boolean,
          )
          definer.define(plugin_class: plugin_class)
        end

        def self.to_sym
          :color
        end

        extend ConfigAttributeCacher

        def config_fail_fast_default_value
          ::Kitchen.tty?
        end
      end
    end
  end
end
