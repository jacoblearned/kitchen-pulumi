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

      def provision(_state)
        stack = config_stack.empty? ? instance.suite.name : config_stack
        dir = "-C #{config_directory}"

        ::Kitchen::Pulumi::ShellOut.run(
          cmd: "up -y -r --show-config -s #{stack} #{dir}",
          logger: logger,
        )
      end

      def destroy(_state)
        stack = config_stack.empty? ? instance.suite.name : config_stack
        dir = "-C #{config_directory}"

        cmds = [
          "destroy -y -r --show-config -s #{stack} #{dir}",
          "stack rm --preserve-config -y -s #{stack} #{dir}",
        ]

        ::Kitchen::Pulumi::ShellOut.run(cmd: cmds, logger: logger)
      rescue ::Kitchen::Pulumi::Error => e
        if e.message.match?(/no stack named '#{stack}' found/)
          puts 'Continuing...'
        end
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

      def configure(stack:, dir: '.')
        config_config.each do |namespace|
          ns = namespace.keys.first
          config_items = namespace.fetch(ns)

          config_items.each do |config_item|
            key = config_item.fetch(:key, '')
            val = config_item.fetch(:value, '')

            ::Kitchen::Pulumi::ShellOut.run(
              cmd: "config set #{ns}:#{key} #{val} -s #{stack} #{dir}",
              logger: logger,
            )
          end
        end
      end
    end
  end
end
