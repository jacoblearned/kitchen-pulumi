# frozen_string_literal: true

require 'kitchen/pulumi/config_attribute'
require 'kitchen/pulumi/config_schemas/systems'

module Kitchen
  module Pulumi
    class ConfigAttribute
      # {include:Kitchen::Pulumi::ConfigSchemas::Systems}
      #
      # If the +systems+ key is omitted then no tests will be executed.
      module Systems
        def self.included(plugin_class)
          definer = ConfigAttributeDefiner.new(
            attribute: self,
            schema: ConfigSchemas::Systems,
          )
          definer.define(plugin_class: plugin_class)
        end

        def self.to_sym
          :systems
        end

        extend ConfigAttributeCacher

        def config_systems_default_value
          []
        end
      end
    end
  end
end
