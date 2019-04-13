# frozen_string_literal: true

require 'kitchen'
require 'kitchen/driver/base'
require 'kitchen/pulumi/error'
require 'kitchen/pulumi/shell_out'
require 'kitchen/pulumi/configurable'
require 'kitchen/pulumi/config_attribute/config'
require 'kitchen/pulumi/config_attribute/directory'
require 'kitchen/pulumi/config_attribute/plugins'
require 'kitchen/pulumi/config_attribute/private_cloud'
require 'kitchen/pulumi/config_attribute/stack'

module Kitchen
  module Driver
    # Driver class implementing the CLI equivalency between Kitchen and Pulumi
    class Pulumi < ::Kitchen::Driver::Base
      kitchen_driver_api_version 2

      include ::Kitchen::Pulumi::Configurable

      # Include config attributes consumable via .kitchen.yml
      include ::Kitchen::Pulumi::ConfigAttribute::Config
      include ::Kitchen::Pulumi::ConfigAttribute::Directory
      include ::Kitchen::Pulumi::ConfigAttribute::Plugins
      include ::Kitchen::Pulumi::ConfigAttribute::PrivateCloud
      include ::Kitchen::Pulumi::ConfigAttribute::Stack

      def create(_state)
        dir = "-C #{config_directory}"
        stack = config_stack.empty? ? instance.suite.name : config_stack
        ppc = "--ppc #{config_private_cloud}" unless config_private_cloud.empty?

        initialize_stack(stack: stack, ppc: ppc, dir: dir)
        configure(stack: stack, dir: dir)
      end

      def initialize_stack(stack:, ppc: '', dir: '.')
        ::Kitchen::Pulumi::ShellOut.run(
          cmd: "stack init #{stack} #{ppc} #{dir}",
          logger: logger,
        )
      rescue ::Kitchen::Pulumi::Error => e
        if e.message.match?(/stack '#{stack}' already exists/)
          puts 'Continuing...'
        end
      end
    end
  end
end
