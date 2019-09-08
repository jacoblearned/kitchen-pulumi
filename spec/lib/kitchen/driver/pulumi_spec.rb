# frozen_string_literal: true

require 'kitchen'
require 'spec_helper'
require 'kitchen/driver/pulumi'

# rubocop:disable Metrics/ParameterLists
# rubocop:disable Metrics/BlockLength
# rubocop:disable Metrics/MethodLength
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
                       test_stack_name: '',
                       backend: '',
                       plugins: [],
                       config: {},
                       config_file: '',
                       secrets: {},
                       refresh_config: false,
                       secrets_provider: '',
                       stack_evolution: [])
    test_stack_name = if test_stack_name.empty?
                        "kitchen-pulumi-test-#{rand(10**10)}"
                      else
                        test_stack_name
                      end

    driver_config = {
      kitchen_root: kitchen_root,
      directory: directory,
      test_stack_name: test_stack_name,
      backend: backend,
      plugins: plugins,
      config: config,
      config_file: config_file,
      secrets: secrets,
      refresh_config: refresh_config,
      secrets_provider: secrets_provider,
      stack_evolution: stack_evolution,
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
        driver = configure_driver(test_stack_name: stack_name)
        expect { driver.create({}) }
          .to output(/Created stack '#{stack_name}'/).to_stdout_from_any_process
      end
    end

    it 'should raise an error when an invalid secrets provider is given' do
      in_tmp_project_dir('test-project') do
        driver = configure_driver(
          test_stack_name: stack_name,
          secrets_provider: 'awskms://1234abcd-12ab-34cd-56-1234567890?region=us-east-1',
        )
        expect { driver.create({}) }
          .to output(/error/).to_stdout_from_any_process
      end
    end

    it 'should allow local backends' do
      in_tmp_project_dir('test-project') do
        driver = configure_driver(test_stack_name: stack_name, backend: 'file://~')
        expect { driver.create({}) }
          .to output(/Created stack '#{stack_name}'/).to_stdout_from_any_process
      end
    end

    it 'should allow local backend with convenient name "local"' do
      in_tmp_project_dir('test-project') do
        driver = configure_driver(test_stack_name: stack_name, backend: 'local')
        expect { driver.create({}) }
          .to output(/Created stack '#{stack_name}'/).to_stdout_from_any_process
      end
    end

    it 'should allow custom config files' do
      in_tmp_project_dir('test-project') do
        config_file = 'custom-test-config-file.yaml'
        driver = configure_driver(test_stack_name: stack_name, config_file: config_file)
        expect { driver.create({}) }
          .to output(/Created stack '#{stack_name}'/).to_stdout_from_any_process
      end
    end

    it 'should raise an error for invalid config/secret maps' do
      in_tmp_project_dir('test-project') do
        invalid_config = { "test-project": ['must be a hash, not an array'] }

        expect { configure_driver(test_stack_name: stack_name, config: invalid_config) }
          .to raise_error(::Kitchen::UserError, /should be a map of maps/)
        expect { configure_driver(test_stack_name: stack_name, secrets: invalid_config) }
          .to raise_error(::Kitchen::UserError, /should be a map of maps/)
      end
    end
  end

  context '#update' do
    it 'should update a stack' do
      in_tmp_project_dir('test-project') do
        config = { 'test-project': { foo: 'bar' } }
        secrets = { 'test-project': { ssh_key: 'ShouldBeSecret' } }
        config_file = 'custom-stack-config-file.yaml'
        stack_evolution = [
          {
            config: { 'test-project': { foo: 'newfoo' } },
            secrets: { 'test-project': { ssh_key: 'NewSecret' } },
          },
          {
            config_file: 'stack-evolution.yaml',
          },
        ]

        driver = configure_driver(
          test_stack_name: stack_name,
          config: config,
          config_file: config_file,
          secrets: secrets,
          refresh_config: true,
          stack_evolution: stack_evolution,
        )

        expected = expect do
          driver.create({})
          driver.update({})
        end

        expected.to output(/test-project-#{stack_name} creating/)
          .to_stdout_from_any_process
        expected.to output(/test-project-#{stack_name} refreshing/)
          .to_stdout_from_any_process
        expected.to output(/bucket_name: kitchen-pulumi-custom-conf-file/)
          .to_stdout_from_any_process
        expected.to output(/ssh_key:\s+\[secret\]/).to_stdout_from_any_process
      end
    end
  end

  context '#destroy' do
    it 'should destroy and remove a stack' do
      in_tmp_project_dir('test-project') do
        config = { 'test-project': { bucket_name: bucket_name } }

        driver = configure_driver(
          test_stack_name: stack_name,
          config: config,
          backend: 'https://api.pulumi.com',
        )

        expect { driver.destroy({}) }
          .to output(/Stack '#{stack_name}' does not exist/)
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
# rubocop:enable Metrics/MethodLength
