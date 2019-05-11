# frozen_string_literal: true

require 'dry/validation'
require 'kitchen/pulumi/config_schemas'
require 'kitchen/pulumi/config_schemas/system'

module Kitchen
  module Pulumi
    module ConfigSchemas
      # The value of the +systems+ key must be a sequence of systems.
      #
      # {include:Kitchen::Pulumi::ConfigSchemas::System}
      Systems = ::Dry::Validation.Schema do
        required(:value).each do
          schema ::Kitchen::Pulumi::ConfigSchemas::System
        end
      end
    end
  end
end
