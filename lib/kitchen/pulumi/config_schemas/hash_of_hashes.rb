# frozen_string_literal: true

require 'dry-validation'
require 'kitchen/pulumi/config_schemas'

module Kitchen
  module Pulumi
    ConfigSchemas::HashOfHashes = ::Dry::Validation.Schema do
      configure do
        def hash_of_hashes?(value)
          value.all? { |_, nested_hash| nested_hash.is_a?(Hash) }
        end
      end

      required(:value).maybe(:hash?, :hash_of_hashes?)
    end
  end
end
