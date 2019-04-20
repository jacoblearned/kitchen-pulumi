# frozen_string_literal: true

require 'kitchen'
require 'kitchen/provisioner/base'
require 'kitchen/pulumi/configurable'

module Kitchen
  module Provisioner
    # Driver class whose call method is invoked when users
    # run kitchen converge
    class Pulumi < ::Kitchen::Provisioner::Base
      kitchen_provisioner_api_version 2

      include ::Kitchen::Pulumi::Configurable

      # Runs stack updates via the instance driver
      def call(state)
        instance.driver.update(state)
      rescue ::Kitchen::Pulumi::Error => e
        raise(::Kitchen::ActionFailed, e.message)
      end
    end
  end
end
