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

class ::Kitchen::Driver::Pulumi < ::Kitchen::Driver::Base
  kitchen_driver_api_version 2

  include ::Kitchen::Pulumi::Configurable

  # Include config attributes consumable via .kitchen.yml
  include ::Kitchen::Pulumi::ConfigAttribute::Config
  include ::Kitchen::Pulumi::ConfigAttribute::Directory
  include ::Kitchen::Pulumi::ConfigAttribute::Plugins
  include ::Kitchen::Pulumi::ConfigAttribute::PrivateCloud
  include ::Kitchen::Pulumi::ConfigAttribute::Stack

  def create(_state)
    stack = config_stack.empty? ? instance.suite.name : config_stack
    ppc = "--ppc #{config_private_cloud}" unless config_private_cloud.empty?

    ::Kitchen::Pulumi::ShellOut.run(
      command: "stack init #{stack} #{ppc} -C #{config_directory}",
      logger: logger,
    )
  rescue ::Kitchen::Pulumi::Error => error
    if error.message =~ /stack '#{stack}' already exists/
      puts 'Continuing...'
    end
  end
end
