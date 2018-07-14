# frozen_string_literal: true

require 'dry-validation'
require 'kitchen/pulumi/config_schemas'

module Kitchen
  module Pulumi
    ConfigSchemas::ArrayOfHashes = ::Dry::Validation.Schema do
      required(:value).each :hash?
    end
  end
end
