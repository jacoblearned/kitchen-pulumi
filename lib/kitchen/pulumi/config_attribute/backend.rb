# frozen_string_literal: true

require 'kitchen/pulumi'
require 'kitchen/pulumi/config_schemas/string'
require 'kitchen/pulumi/config_attribute_cacher'
require 'kitchen/pulumi/config_attribute_definer'

module Kitchen
  module Pulumi
    module ConfigAttribute
      # Attribute used to specify the Pulumi backend to use.
      # It contains the URL to the backend, local or remote
      module Backend
        def self.included(plugin_class)
          definer = ConfigAttributeDefiner.new(
            attribute: self,
            schema: ConfigSchemas::String,
          )
          definer.define(plugin_class: plugin_class)
        end

        def self.to_sym
          :backend
        end

        extend ConfigAttributeCacher

        def config_backend_default_value
          ''
        end
      end
    end
  end
end
