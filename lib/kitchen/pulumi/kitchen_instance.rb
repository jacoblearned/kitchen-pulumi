# frozen_string_literal: true

require 'delegate'
require 'kitchen'
require 'kitchen/pulumi'

module Kitchen
  module Pulumi
    class KitchenInstance < DelegateClass ::Kitchen::Instance
    end
  end
end
