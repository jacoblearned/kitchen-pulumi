# frozen_string_literal: true

require 'kitchen'
require 'kitchen/pulumi'
require 'kitchen/pulumi/kitchen_instance'
require 'kitchen/pulumi/version'

module Kitchen
  module Pulumi
    # Module for plugins which are configurable via user-provided values
    # in .kitchen.yaml
    module Configurable
      # Alternative implementation of Kitchen::Configurable#finalize_config!
      # which validates the configuration before attempting to expand paths.
      # See https://github.com/test-kitchen/test-kitchen/issues/1229
      def finalize_config!(kitchen_instance)
        kitchen_instance || raise(::Kitchen::ClientError,
                                  "Instance must be provided to #{self}")
        @instance = KitchenInstance.new(kitchen_instance)
        validate_config!
        expand_paths!
        load_needed_dependencies!
        self
      end
    end
  end
end
