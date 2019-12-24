# frozen_string_literal: true

require 'kitchen'
require 'kitchen/provisioner/base'
require 'kitchen/pulumi/configurable'

module Kitchen
  # This namespace is defined by Kitchen.
  #
  # @see https://www.rubydoc.info/gems/test-kitchen/Kitchen/Provisioner
  module Provisioner
    # Provisioner class whose call method is invoked when users
    # run `kitchen converge`
    #
    # @author Jacob Learned
    class Pulumi < ::Kitchen::Provisioner::Base
      kitchen_provisioner_api_version 2

      include ::Kitchen::Pulumi::Configurable

      # Runs stack updates via the instance driver which shells out
      #   to `pulumi up`
      #
      # @param state [::Hash] the current kitchen state
      # @raise [Kitchen::ActionFailed] if an error occurs during update
      # @return void
      def call(state)
        instance.driver.update(state)
      rescue ::Kitchen::Pulumi::Error => e
        raise(::Kitchen::ActionFailed, e.message)
      end
    end
  end
end
