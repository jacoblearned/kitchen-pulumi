# frozen_string_literal: true

require 'yaml'
require 'kitchen'
require 'kitchen/driver/base'
require 'kitchen/pulumi/error'
require 'kitchen/pulumi/shell_out'
require 'kitchen/pulumi/deep_merge.rb'
require 'kitchen/pulumi/configurable'
require 'kitchen/pulumi/command/input'
require 'kitchen/pulumi/command/output'
require 'kitchen/pulumi/config_attribute/config'
require 'kitchen/pulumi/config_attribute/config_file'
require 'kitchen/pulumi/config_attribute/directory'
require 'kitchen/pulumi/config_attribute/plugins'
require 'kitchen/pulumi/config_attribute/backend'
require 'kitchen/pulumi/config_attribute/secrets'
require 'kitchen/pulumi/config_attribute/test_stack_name'
require 'kitchen/pulumi/config_attribute/stack_evolution'
require 'kitchen/pulumi/config_attribute/refresh_config'
require 'kitchen/pulumi/config_attribute/secrets_provider'

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
      include ::Kitchen::Pulumi::ConfigAttribute::Backend
      include ::Kitchen::Pulumi::ConfigAttribute::Secrets
      include ::Kitchen::Pulumi::ConfigAttribute::TestStackName
      include ::Kitchen::Pulumi::ConfigAttribute::StackEvolution
      include ::Kitchen::Pulumi::ConfigAttribute::RefreshConfig
      include ::Kitchen::Pulumi::ConfigAttribute::SecretsProvider

      def create(_state)
        dir = "-C #{config_directory}"
        login
        initialize_stack(stack, dir)
      end

      def update(_state)
        dir = "-C #{config_directory}"

        ::Kitchen::Pulumi.with_temp_conf(config_file) do |temp_conf_file|
          login
          refresh_config(stack, temp_conf_file, dir) if config_refresh_config
          configure(config_config, stack, temp_conf_file, dir)
          configure(config_secrets, stack, temp_conf_file, dir, is_secret: true)
          update_stack(stack, temp_conf_file, dir)
          evolve_stack(stack, temp_conf_file, dir) unless config_stack_evolution.empty?
        end
      end

      def destroy(_state)
        dir = "-C #{config_directory}"

        cmds = [
          "destroy -y -r --show-config -s #{stack} #{dir}",
          "stack rm --preserve-config -y -s #{stack} #{dir}",
        ]

        login
        ::Kitchen::Pulumi::ShellOut.run(cmd: cmds, logger: logger)
      rescue ::Kitchen::Pulumi::Error => e
        if e.message.match?(/no stack named '#{stack}' found/) || (
          e.message.match?(/failed to load checkpoint/) && config_backend == 'local'
        )
          puts "Stack '#{stack}' does not exist, continuing..."
        end
      end

      def stack
        return config_test_stack_name unless config_test_stack_name.empty?

        "#{instance.suite.name}-#{instance.platform.name}"
      end

      def secrets_provider(flag: false)
        return '' if config_secrets_provider.empty?

        return "--secrets-provider=\"#{config_secrets_provider}\"" if flag

        config_secrets_provider
      end

      def login
        backend = config_backend == 'local' ? '--local' : config_backend
        ::Kitchen::Pulumi::ShellOut.run(
          cmd: "login #{backend}",
          logger: logger,
        )
      end

      def initialize_stack(stack, dir = '')
        ::Kitchen::Pulumi::ShellOut.run(
          cmd: "stack init #{stack} #{dir} #{secrets_provider(flag: true)}",
          logger: logger,
        )
      rescue ::Kitchen::Pulumi::Error => e
        puts 'Continuing...' if e.message.match?(/stack '#{stack}' already exists/)
      end

      def configure(stack_confs, stack, conf_file, dir = '', is_secret: false)
        secret = is_secret ? '--secret' : ''
        config_flag = config_file(conf_file, flag: true)
        base_cmd = "config set #{secret} -s #{stack} #{dir} #{config_flag}"

        stack_confs.each do |namespace, stack_settings|
          stack_settings.each do |key, val|
            ::Kitchen::Pulumi::ShellOut.run(
              cmd: "#{base_cmd} #{namespace}:#{key} \"#{val}\"",
              logger: logger,
            )
          end
        end
      end

      def refresh_config(stack, conf_file, dir = '')
        ::Kitchen::Pulumi::ShellOut.run(
          cmd: "config refresh -s #{stack} #{dir} #{config_file(conf_file, flag: true)}",
          logger: logger,
        )
      rescue ::Kitchen::Pulumi::Error => e
        puts 'Continuing...' if e.message.match?(/no previous deployment/)
      end

      def config_file(conf_file = '', flag: false)
        file = conf_file.empty? ? config_config_file : conf_file
        return '' if File.directory?(file) || file.empty?

        return "--config-file #{file}" if flag

        file
      end

      def update_stack(stack, conf_file, dir = '')
        base_cmd = "up -y -r --show-config -s #{stack} #{dir}"
        ::Kitchen::Pulumi::ShellOut.run(
          cmd: "#{base_cmd} #{config_file(conf_file, flag: true)}",
          logger: logger,
        )
      end

      def evolve_stack(stack, conf_file, dir = '')
        config_stack_evolution.each do |evolution|
          new_conf_file = config_file(evolution.fetch(:config_file, ''))
          new_stack_confs = evolution.fetch(:config, {})
          new_stack_secrets = evolution.fetch(:secrets, {})

          rewrite_config_file(new_conf_file, conf_file)

          configure(new_stack_confs, stack, conf_file, dir)
          configure(new_stack_secrets, stack, conf_file, dir, is_secret: true)
          update_stack(stack, conf_file, dir)
        end
      end

      def rewrite_config_file(new_conf_file, old_conf_file)
        return if new_conf_file.empty?

        old_conf = YAML.load_file(old_conf_file)
        new_conf_file = File.join(config_directory, new_conf_file)
        return unless File.exist?(new_conf_file)

        new_conf = old_conf.deep_merge(YAML.load_file(new_conf_file))
        File.write(old_conf_file, new_conf.to_yaml)
      end

      def stack_inputs(&block)
        ::Kitchen::Pulumi::Command::Input.run(
          directory: config_directory,
          stack: stack,
          conf_file: config_file(flag: true),
          logger: logger,
          &block
        )

        self
      rescue ::Kitchen::Pulumi::Error => e
        raise ::Kitchen::ActionFailed, e.message
      end

      def stack_outputs(&block)
        ::Kitchen::Pulumi::Command::Output.run(
          directory: config_directory,
          stack: stack,
          logger: logger,
          &block
        )

        self
      rescue ::Kitchen::Pulumi::Error => e
        raise ::Kitchen::ActionFailed, e.message
      end
    end
  end
end
