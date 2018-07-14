# frozen_string_literal: true

module Kitchen
  module Pulumi
    # Namespace for the config attribute retrieval cache. Allows plugins that
    # include ConfigAttributes to refer to config values by instance variables
    # of the form 'config_<attribute name>'
    module ConfigAttributeCacher
      # Defines an attribute cache for a config attribute extending this module
      def self.extended(config_attribute)
        config_attribute.define_cache
      end

      # Sets an instance variable for a config attribute extending this module
      def define_cache(attribute: to_sym)
        attr = "config_#{attribute}"

        define_method(attr) do
          if instance_variable_defined?("@#{attr}")
            instance_variable_get("@#{attr}")
          else
            instance_variable_set("@#{attr}", config.fetch(attribute))
          end
        end
      end
    end
  end
end
