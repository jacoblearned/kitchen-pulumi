# frozen_string_literal: true

require 'kitchen/pulumi/config_attribute'
require 'kitchen/pulumi/config_schemas/stack_settings_hash'
require 'kitchen/pulumi/config_attribute_cacher'
require 'kitchen/pulumi/config_attribute_definer'

module Kitchen
  module Pulumi
    module ConfigAttribute
      # Module used for the 'config' instance var on an
      # instance driver. The driver will set the Pulumi stack
      # configs for each of the namespaces provided.
      module Secrets
        def self.included(plugin)
          definer = ConfigAttributeDefiner.new(
            attribute: self,
            schema: ConfigSchemas::StackSettingsHash,
          )
          definer.define(plugin_class: plugin)
        end

        def self.to_sym
          :secrets
        end

        extend ConfigAttributeCacher

        def config_secrets_default_value
          {}
        end
      end
    end
  end
end
