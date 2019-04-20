# frozen_string_literal: true

require 'kitchen/pulumi'
require 'kitchen/pulumi/config_schemas/string'
require 'kitchen/pulumi/config_attribute_cacher'
require 'kitchen/pulumi/file_path_config_attribute_definer'

module Kitchen
  module Pulumi
    module ConfigAttribute
      # Attribute used to specify the config_file containing a project's
      # stack configuration
      module ConfigFile
        def self.included(plugin_class)
          definer = FilePathConfigAttributeDefiner.new(
            attribute: self,
            schema: ConfigSchemas::String,
          )
          definer.define(plugin_class: plugin_class)
        end

        def self.to_sym
          :config_file
        end

        extend ConfigAttributeCacher

        def config_config_file_default_value
          ''
        end
      end
    end
  end
end
