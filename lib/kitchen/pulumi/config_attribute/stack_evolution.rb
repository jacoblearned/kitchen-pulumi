# frozen_string_literal: true

require 'kitchen/pulumi/config_attribute'
require 'kitchen/pulumi/config_schemas/config_evolution_array'
require 'kitchen/pulumi/config_attribute_cacher'
require 'kitchen/pulumi/config_attribute_definer'

module Kitchen
  module Pulumi
    module ConfigAttribute
      # Module used for the 'config_evolution' instance var on an
      # instance driver. The driver will set the Pulumi stack
      # configs for each config in the array and then call `pulumi up`
      # between each item in the evolution list. This has the effect of
      # testing a user's stack configuration changes over time.
      module StackEvolution
        def self.included(plugin)
          definer = ConfigAttributeDefiner.new(
            attribute: self,
            schema: ConfigSchemas::ConfigEvolutionArray,
          )
          definer.define(plugin_class: plugin)
        end

        def self.to_sym
          :stack_evolution
        end

        extend ConfigAttributeCacher

        def config_stack_evolution_default_value
          []
        end
      end
    end
  end
end
