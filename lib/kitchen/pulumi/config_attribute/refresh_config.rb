# frozen_string_literal: true

require 'kitchen/pulumi'
require 'kitchen/pulumi/config_schemas/boolean'
require 'kitchen/pulumi/config_attribute_cacher'
require 'kitchen/pulumi/config_attribute_definer'

module Kitchen
  module Pulumi
    module ConfigAttribute
      # Attribute used to determine if the stack config should be
      # refreshed from the remote before every `pulumi up` command
      module RefreshConfig
        def self.included(plugin_class)
          definer = ConfigAttributeDefiner.new(
            attribute: self,
            schema: ConfigSchemas::Boolean,
          )
          definer.define(plugin_class: plugin_class)
        end

        def self.to_sym
          :refresh_config
        end

        extend ConfigAttributeCacher

        def config_refresh_config_default_value
          false
        end
      end
    end
  end
end
