# frozen_string_literal: true

require 'kitchen'
require 'kitchen/driver/base'
require 'kitchen/pulumi/error'
require 'kitchen/pulumi/shell_out'
require 'kitchen/pulumi/configurable'
require 'kitchen/pulumi/config_attribute/config'
require 'kitchen/pulumi/config_attribute/config_file'
require 'kitchen/pulumi/config_attribute/directory'
require 'kitchen/pulumi/config_attribute/plugins'
require 'kitchen/pulumi/config_attribute/private_cloud'
require 'kitchen/pulumi/config_attribute/secrets'
require 'kitchen/pulumi/config_attribute/stack'

module Kitchen
  module Driver
    # Driver class implementing the CLI equivalency between Kitchen and Pulumi
    class Pulumi < ::Kitchen::Driver::Base
      kitchen_driver_api_version 2

      include ::Kitchen::Pulumi::Configurable

      # Include config attributes consumable via .kitchen.yml
      include ::Kitchen::Pulumi::ConfigAttribute::Config
      include ::Kitchen::Pulumi::ConfigAttribute::ConfigFile
      include ::Kitchen::Pulumi::ConfigAttribute::Directory
      include ::Kitchen::Pulumi::ConfigAttribute::Plugins
      include ::Kitchen::Pulumi::ConfigAttribute::PrivateCloud
      include ::Kitchen::Pulumi::ConfigAttribute::Secrets
      include ::Kitchen::Pulumi::ConfigAttribute::Stack

      def create(_state)
        dir = "-C #{config_directory}"
        stack = config_stack.empty? ? instance.suite.name : config_stack
        ppc = "--ppc #{config_private_cloud}" unless config_private_cloud.empty?

        initialize_stack(stack, ppc, dir)
        configure(config_config, stack, dir)
        configure(config_secrets, stack, dir, is_secret: true)
      end

      def update(_state)
        stack = config_stack.empty? ? instance.suite.name : config_stack
        dir = "-C #{config_directory}"
        conf_file = config_file

        ::Kitchen::Pulumi::ShellOut.run(
          cmd: "up -y -r --show-config -s #{stack} #{dir} #{conf_file}",
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

      def initialize_stack(stack, ppc = '', dir = '')
        ::Kitchen::Pulumi::ShellOut.run(
          cmd: "stack init #{stack} #{ppc} #{dir}",
          logger: logger,
        )
      rescue ::Kitchen::Pulumi::Error => e
        if e.message.match?(/stack '#{stack}' already exists/)
          puts 'Continuing...'
        end
      end

      def configure(stack_settings_hash, stack, dir = '', is_secret: false)
        secret = is_secret ? '--secret' : ''
        base_cmd = "config set #{secret} -s #{stack} #{dir} #{config_file}"

        stack_settings_hash.each do |namespace, stack_settings|
          stack_settings.each do |key, val|
            ::Kitchen::Pulumi::ShellOut.run(
              cmd: "#{base_cmd} #{namespace}:#{key} #{val}",
              logger: logger,
            )
          end
        end
      end

      def config_file
        file = config_config_file
        return '' if File.directory?(file) || file.empty?

        "--config-file #{file}"
      end
    end
  end
end
