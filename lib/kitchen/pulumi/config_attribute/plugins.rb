# frozen_string_literal: true

require 'kitchen/pulumi/config_attribute'
require 'kitchen/pulumi/config_schemas/array_of_hashes'
require 'kitchen/pulumi/config_attribute_cacher'
require 'kitchen/pulumi/config_attribute_definer'

module Kitchen
  module Pulumi
    module ConfigAttribute
      # Module used for specifying any required plugins that a project
      # will need to provision its resources.
      module Plugins
        def self.included(plugin)
          definer = ConfigAttributeDefiner.new(
            attribute: self,
            schema: ConfigSchemas::ArrayOfHashes,
          )
          definer.define(plugin_class: plugin)
        end

        def self.to_sym
          :plugins
        end

        extend ConfigAttributeCacher

        def config_plugins_default_value
          []
        end
      end
    end
  end
end
