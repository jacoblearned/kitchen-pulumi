# frozen_string_literal: true

require 'kitchen/pulumi'
require 'kitchen/pulumi/config_schemas/string'
require 'kitchen/pulumi/config_attribute_cacher'
require 'kitchen/pulumi/file_path_config_attribute_definer'

module Kitchen
  module Pulumi
    module ConfigAttribute
      # Attribute used to specify the directory containing a project's
      # Pulumi.yaml file
      module Directory
        def self.included(plugin_class)
          definer = FilePathConfigAttributeDefiner.new(
            attribute: self,
            schema: ConfigSchemas::String,
          )
          definer.definer(plugin_class: plugin_class)
        end

        def self.to_sym
          :directory
        end

        extend config_attribute_cacher

        def config_directory_default_value
          '.'
        end
      end
    end
  end
end
