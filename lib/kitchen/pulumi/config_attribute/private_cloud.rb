# frozen_string_literal: true

require 'kitchen/pulumi'
require 'kitchen/pulumi/config_schemas/string'
require 'kitchen/pulumi/config_attribute_cacher'
require 'kitchen/pulumi/config_attribute_definer'

module Kitchen
  module Pulumi
    module ConfigAttribute
      # Attribute used to specify the Pulumi Private Cloud URL for a stack
      module PrivateCloud
        def self.included(plugin_class)
          definer = ConfigAttributeDefiner.new(
            attribute: self,
            schema: ConfigSchemas::String,
          )
          definer.define(plugin_class: plugin_class)
        end

        def self.to_sym
          :private_cloud
        end

        extend ConfigAttributeCacher

        def config_private_cloud_default_value
          ''
        end
      end
    end
  end
end
