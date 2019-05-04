# frozen_string_literal: true

require 'dry-validation'
require 'kitchen/pulumi/config_schemas'

module Kitchen
  module Pulumi
    ConfigSchemas::Boolean = ::Dry::Validation.Schema do
      required(:value).maybe :bool?
    end
  end
end
