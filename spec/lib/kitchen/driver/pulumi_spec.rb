# frozen_string_literal: true

require 'kitchen'
require 'spec_helper'
require 'kitchen/driver/pulumi'

# rubocop:disable Metrics/ParameterLists
# rubocop:disable Metrics/BlockLength
describe ::Kitchen::Driver::Pulumi do
  let(:stack_name) { "test-stack-#{rand(10**10)}" }
  let(:bucket_name) { 'foo-bucket' }

  def kitchen_instance(driver_instance, kitchen_root)
    ::Kitchen::Instance.new(
      driver: driver_instance,
      logger: driver_instance.send(:logger),
      platform: ::Kitchen::Platform.new(name: 'test-platform'),
      provisioner: ::Kitchen::Provisioner::Base.new,
      suite: ::Kitchen::Suite.new(name: 'test-suite'),
      transport: ::Kitchen::Transport::Base.new,
      verifier: ::Kitchen::Verifier::Base.new,
      lifecycle_hooks: ::Kitchen::LifecycleHooks.new({}),
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
                       config: {},
                       secrets: {})
    driver_config = {
      kitchen_root: kitchen_root,
      directory: directory,
      stack: stack.empty? ? "kitchen-pulumi-test-#{rand(10**10)}" : stack,
      private_cloud: private_cloud,
      plugins: plugins,
      config: config,
      secrets: secrets,
    }

    driver = described_class.new(driver_config)
    kitchen_instance = kitchen_instance(driver, '.')
    driver.finalize_config!(kitchen_instance)
    driver
  end

  context '#create' do
    it 'should initialize a stack' do
      in_tmp_project_dir('test-project') do
        driver = configure_driver
        expect { driver.create({}) }
          .to output(/Created stack 'kitchen-pulumi-test/)
          .to_stdout_from_any_process
      end
    end

    it 'should allow overrides of the stack name' do
      in_tmp_project_dir('test-project') do
        driver = configure_driver(stack: stack_name)
        expect { driver.create({}) }
          .to output(/Created stack '#{stack_name}'/).to_stdout_from_any_process
      end
    end

    it 'should raise an error for invalid config/secret maps' do
      in_tmp_project_dir('test-project') do
        invalid_config = { "test-project": ['must be a hash, not an array'] }

        expect { configure_driver(stack: stack_name, config: invalid_config) }
          .to raise_error(::Kitchen::UserError, /should be a map of maps/)
        expect { configure_driver(stack: stack_name, secrets: invalid_config) }
          .to raise_error(::Kitchen::UserError, /should be a map of maps/)
      end
    end
  end

  context '#provision' do
    it 'should update a stack' do
      in_tmp_project_dir('test-project') do
        config = { 'test-project': { bucket_name: bucket_name } }
        secrets = { 'test-project': { ssh_key: 'ShouldBeSecret' } }

        driver = configure_driver(
          stack: stack_name,
          config: config,
          secrets: secrets,
        )

        expected = expect do
          driver.create({})
          driver.update({})
          driver.update({})
        end
        expected.to output(/Stack test-project-#{stack_name} created/)
          .to_stdout_from_any_process
        expected.to output(/ssh_key:\s+\[secret\]/).to_stdout_from_any_process
      end
    end
  end

  context '#destroy' do
    it 'should destroy and remove a stack' do
      in_tmp_project_dir('test-project') do
        config = { 'test-project': { bucket_name: bucket_name } }

        driver = configure_driver(stack: stack_name, config: config)

        expect { driver.destroy({}) }
          .to output(/no stack named '#{stack_name}' found/)
          .to_stdout_from_any_process

        expect do
          driver.create({})
          driver.update({})
          driver.destroy({})
        end.to output(/Stack test-project-#{stack_name} deleted/)
          .to_stdout_from_any_process
      end
    end
  end
end
# rubocop:enable Metrics/ParameterLists
# rubocop:enable Metrics/BlockLength
