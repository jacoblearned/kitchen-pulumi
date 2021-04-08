# frozen_string_literal: true

require 'yaml'
require 'kitchen'
require 'kitchen/driver/base'
require 'kitchen/pulumi/error'
require 'kitchen/pulumi/shell_out'
require 'kitchen/pulumi/deep_merge'
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
require 'kitchen/pulumi/config_attribute/preserve_config'

module Kitchen
  # This namespace is defined by Kitchen.
  #
  # @see https://www.rubydoc.info/gems/test-kitchen/Kitchen/Driver
  module Driver
    # Driver class implementing the CLI equivalency between Kitchen and Pulumi
    #
    # @author Jacob Learned
    class Pulumi < ::Kitchen::Driver::Base
      kitchen_driver_api_version 2

      include ::Kitchen::Pulumi::Configurable
      include ::Kitchen::Logging

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
      include ::Kitchen::Pulumi::ConfigAttribute::PreserveConfig

      # Initializes a stack via `pulumi stack init` & run a preview of changes
      #
      # @param _state [::Hash] the current kitchen state
      # @return [void]
      def create(_state)
        dir = "-C #{config_directory}"
        login
        initialize_stack(stack, dir)

        ::Kitchen::Pulumi.with_temp_conf(config_file) do |temp_conf_file|
          refresh_config(stack, temp_conf_file, dir) if config_refresh_config
          configure(config_config, stack, temp_conf_file, dir)
          configure(config_secrets, stack, temp_conf_file, dir, is_secret: true)
          preview_stack(stack, temp_conf_file, dir)
        end
      end

      # Sets stack config values via `pulumi config` and updates the stack via `pulumi up`
      #
      # @param _state [::Hash] the current kitchen state
      # @param config_only [Boolean] specify true to update the stack config without
      #   applying changes to the stack via `pulumi up`. This is used primarily for
      #   setting the correct stack inputs by successively applying `pulumi config` in
      #   the order of precedence for specifying stack config values in the config file or
      #   kitchen.yml file.
      #
      # for block {|temp_conf_file| ...}
      # @yield [temp_conf_file] provides the path to the temporary config file used
      #
      # @return [void]
      def update(_state, config_only: false)
        dir = "-C #{config_directory}"

        ::Kitchen::Pulumi.with_temp_conf(config_file) do |temp_conf_file|
          login
          refresh_config(stack, temp_conf_file, dir) if config_refresh_config
          configure(config_config, stack, temp_conf_file, dir)
          configure(config_secrets, stack, temp_conf_file, dir, is_secret: true)
          update_stack(stack, temp_conf_file, dir) unless config_only

          unless config_stack_evolution.empty?
            evolve_stack(stack, temp_conf_file, dir, config_only: config_only)
          end

          yield temp_conf_file if block_given?
        end
      end

      # Destroys a stack via `pulumi destroy`
      #
      # @param _state [::Hash] the current kitchen state
      # @return [void]
      def destroy(_state)
        dir = "-C #{config_directory}"

        cmds = [
          "destroy -y -r --show-config -s #{stack} #{dir}",
          "stack rm #{preserve_config} -y -s #{stack} #{dir}",
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

      # Returns `--preserve-config` if the `preserve_config` instance attribute is set
      #
      # @return [String] either `''` or `--preserve-config`
      def preserve_config
        return '' unless config_preserve_config

        '--preserve-config'
      end

      # Returns the name of the current stack to use. If the `test_stack_name` driver
      # attribute is set, then it uses that one, otherwise it will be
      # `<suite name>-<platform name>`
      #
      # @return [String] either the empty string or '--preserve-config'
      def stack
        return config_test_stack_name unless config_test_stack_name.empty?

        "#{instance.suite.name}-#{instance.platform.name}"
      end

      # Returns the name of the secrets provider, if set, optionally as a Pulumi CLI flag
      #
      # @param flag [Boolean] specify true to prepend `--secrets-provider=`` to the name
      # @return [String] value to use for the secrets provider
      def secrets_provider(flag: false)
        return '' if config_secrets_provider.empty?

        return "--secrets-provider=\"#{config_secrets_provider}\"" if flag

        config_secrets_provider
      end

      # Logs in to the Pulumi backend set for the instance via `pulumi login`
      #
      # @return [void]
      def login
        backend = config_backend == 'local' ? '--local' : config_backend
        ::Kitchen::Pulumi::ShellOut.run(
          cmd: "login #{backend}",
          logger: logger,
        )
      end

      # Initializes a stack in the current directory unless another is provided
      #
      # @param stack [String] name of the stack to initialize
      # @param dir [String] path to the directory to run Pulumi commands in
      def initialize_stack(stack, dir = '')
        ::Kitchen::Pulumi::ShellOut.run(
          cmd: "stack init #{stack} #{dir} #{secrets_provider(flag: true)}",
          logger: logger,
        )
      rescue ::Kitchen::Pulumi::Error => e
        puts 'Continuing...' if e.message.match?(/stack '#{stack}' already exists/)
      end

      # Configures a stack in the current directory unless another is provided
      #
      # @param stack_confs [::Hash] hash specifying the stack config for the instance
      # @param stack [String] name of the stack to configure
      # @param conf_file [String] path to a stack config file to use for configuration
      # @param dir [String] path to the directory to run Pulumi commands in
      # @param is_secret [Boolean] specify true to set the given stack config as secrets
      # @return [void]
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

      # Refreshes a stack's config on the specified config file
      #
      # @param stack [String] name of the stack being refreshed
      # @param conf_file [String] path to a stack config file to use for configuration
      # @param dir [String] path to the directory to run Pulumi commands in
      # @return [void]
      def refresh_config(stack, conf_file, dir = '')
        ::Kitchen::Pulumi::ShellOut.run(
          cmd: "config refresh -s #{stack} #{dir} #{config_file(conf_file, flag: true)}",
          logger: logger,
        )
      rescue ::Kitchen::Pulumi::Error => e
        puts 'Continuing...' if e.message.match?(/no previous deployment/)
      end

      # Get the value of the config file to use, if set on instance or provided as param,
      # optionally as a command line flag `--config-file`
      #
      # @param conf_file [String] path to a stack config file to use for configuration
      # @param flag [Boolean] specify true to prepend '--config-file ' to the config file
      # @return [String] the path to the config file or its corresponding CLI flag
      def config_file(conf_file = '', flag: false)
        file = conf_file.empty? ? config_config_file : conf_file
        return '' if File.directory?(file) || file.empty?

        return "--config-file #{file}" if flag

        file
      end

      # Updates a stack via `pulumi up` according to instance attributes
      #
      # @param (see #refresh_config)
      # @return [void]
      def update_stack(stack, conf_file, dir = '')
        base_cmd = "up -y -r --show-config -s #{stack} #{dir}"
        ::Kitchen::Pulumi::ShellOut.run(
          cmd: "#{base_cmd} #{config_file(conf_file, flag: true)}",
          logger: logger,
        )
      end

      # Preview effects of `pulumi up`
      #
      # @param stack [String] name of the stack being refreshed
      # @param conf_file [String] path to a stack config file to use for configuration
      # @param dir [String] path to the directory to run Pulumi commands in
      # @return [void]
      def preview_stack(stack, conf_file, dir = '')
        base_cmd = "preview -r --show-config -s #{stack} #{dir}"
        ::Kitchen::Pulumi::ShellOut.run(
          cmd: "#{base_cmd} #{config_file(conf_file, flag: true)}",
          logger: logger,
        )
      end

      # Evolves a stack via successive calls to `pulumi config set` and `pulumi up`
      # according to the `stack_evolution` instance attribute, if set. This permits
      # testing stack config changes over time.
      #
      # @param (see #refresh_config)
      # @param config_only [Boolean] specify true to prevent running `pulumi up`
      # @return [void]
      def evolve_stack(stack, conf_file, dir = '', config_only: false)
        config_stack_evolution.each do |evolution|
          new_conf_file = config_file(evolution.fetch(:config_file, ''))
          new_stack_confs = evolution.fetch(:config, {})
          new_stack_secrets = evolution.fetch(:secrets, {})

          rewrite_config_file(new_conf_file, conf_file)

          configure(new_stack_confs, stack, conf_file, dir)
          configure(new_stack_secrets, stack, conf_file, dir, is_secret: true)
          update_stack(stack, conf_file, dir) unless config_only
        end
      end

      # Rewrites a temporary config file by merging the contents of the new config file
      # into the old config file. This is used during stack evolution to ensure that
      # stack config changes for each evolution step are implemented correctly if the
      # user has provided a new config file to use for a step.
      #
      # @param new_conf_file [String] the path to the new config file to use
      # @param old_conf_file [String] the path to the config file to overwrite
      # @return [void]
      def rewrite_config_file(new_conf_file, old_conf_file)
        return if new_conf_file.empty?

        old_conf = YAML.load_file(old_conf_file)
        new_conf_file = File.join(config_directory, new_conf_file)
        return unless File.exist?(new_conf_file)

        new_conf = old_conf.deep_merge(YAML.load_file(new_conf_file))
        File.write(old_conf_file, new_conf.to_yaml)
      end

      # Retrieves the fully resolved stack inputs based on the current configuration
      # of the stack via `pulumi config`
      #
      # @param block [Block] block to run with stack inputs yielded to it
      #
      # for block {|stack_inputs| ... }
      # @yield [stack_inputs] yields a hash of stack inputs
      #
      # @raise [Kitchen::ActionFailed] if an error occurs retrieving stack inputs
      # @return [self]
      def stack_inputs(&block)
        update({}, config_only: true) do |temp_conf_file|
          ::Kitchen::Pulumi::Command::Input.run(
            directory: config_directory,
            stack: stack,
            conf_file: config_file(temp_conf_file, flag: true),
            logger: logger,
            &block
          )
        end

        self
      rescue ::Kitchen::Pulumi::Error => e
        raise ::Kitchen::ActionFailed, e.message
      end

      # Retrieves stack outputs via `pulumi stack output`
      #
      # @param block [Block] block to run with stack outputs yielded to it
      #
      # for block {|stack_outputs| ... }
      # @yield [stack_outputs] yields a hash of stack outputs
      #
      # @raise [Kitchen::ActionFailed] if an error occurs retrieving stack outputs
      # @return [self]
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

      private

      # @return [Logger] the common logger
      # @api private
      def logger
        Kitchen.logger
      end
    end
  end
end
