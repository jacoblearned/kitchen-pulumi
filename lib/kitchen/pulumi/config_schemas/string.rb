# frozen_string_literal: true

require 'dry-validation'
require 'kitchen/pulumi/config_schemas'

module Kitchen
  module Pulumi
    ConfigSchemas::String = ::Dry::Validation.Schema do
      required(:value).maybe :str?
    end
  end
end
