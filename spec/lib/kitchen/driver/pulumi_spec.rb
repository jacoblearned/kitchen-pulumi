# frozen_string_literal: true

require 'kitchen'
require 'spec_helper'
require 'kitchen/driver/pulumi'

# rubocop:disable Metrics/ParameterLists
# rubocop:disable Metrics/BlockLength
describe ::Kitchen::Driver::Pulumi do
  def kitchen_instance(driver_instance, kitchen_root)
    ::Kitchen::Instance.new(
      driver: driver_instance,
      logger: driver_instance.send(:logger),
      platform: ::Kitchen::Platform.new(name: 'test-platform'),
      provisioner: ::Kitchen::Provisioner::Base.new,
      suite: ::Kitchen::Suite.new(name: 'test-suite'),
      transport: ::Kitchen::Transport::Base.new,
      verifier: ::Kitchen::Verifier::Base.new,
      state_file: ::Kitchen::StateFile.new(
        kitchen_root,
        'test-suite-test-platfrom',
      ),
    )
  end

  def configure_driver(directory: '.',
                       kitchen_root: '.',
                       stack: '',
                       private_cloud: '',
                       plugins: [],
                       config: [])
    config = {
      kitchen_root: kitchen_root,
      directory: directory,
      stack: stack,
      private_cloud: private_cloud,
      plugins: plugins,
      config: config,
    }

    driver = described_class.new(config)
    kitchen_instance = kitchen_instance(driver, '.')
    driver.finalize_config!(kitchen_instance)
    driver
  end

  context '#create' do
    it 'should initialize a stack' do
      in_tmp_project_dir('test-project') do
        driver = configure_driver
        expect { driver.create({}) }
          .to output(/Created stack 'test-suite'/).to_stdout_from_any_process
      end
    end

    it 'should allow overrides of the stack name' do
      in_tmp_project_dir('test-project') do
        driver = configure_driver(stack: 'dev')
        expect { driver.create({}) }
          .to output(/Created stack 'dev'/).to_stdout_from_any_process
      end
    end
  end
end
# rubocop:enable Metrics/ParameterLists
# rubocop:enable Metrics/BlockLength