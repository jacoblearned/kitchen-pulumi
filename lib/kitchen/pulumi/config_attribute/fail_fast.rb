# frozen_string_literal: true

require 'kitchen/pulumi'
require 'kitchen/pulumi/config_schemas/boolean'
require 'kitchen/pulumi/config_attribute_cacher'
require 'kitchen/pulumi/config_attribute_definer'

module Kitchen
  module Pulumi
    module ConfigAttribute
      # Attribute used to determine if Kitchen should halt on the
      # first error during verification.
      module FailFast
        def self.included(plugin_class)
          definer = ConfigAttributeDefiner.new(
            attribute: self,
            schema: ConfigSchemas::Boolean,
          )
          definer.define(plugin_class: plugin_class)
        end

        def self.to_sym
          :fail_fast
        end

        extend ConfigAttributeCacher

        def config_fail_fast_default_value
          true
        end
      end
    end
  end
end
