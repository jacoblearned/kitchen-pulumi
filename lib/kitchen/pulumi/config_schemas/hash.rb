# frozen_string_literal: true

require 'dry-validation'
require 'kitchen/pulumi/config_schemas'

module Kitchen
  module Pulumi
    ConfigSchemas::Hash = ::Dry::Validation.Schema do
      input :hash?
    end
  end
end
