# frozen_string_literal: true

require 'kitchen'
require 'kitchen/pulumi/config_attribute/color'
require 'kitchen/pulumi/config_attribute/fail_fast'
require 'kitchen/pulumi/config_attribute/systems'
require 'kitchen/pulumi/configurable'
require 'kitchen/pulumi/error'
require 'kitchen/pulumi/inspec_options_mapper'

module Kitchen
  # This namespace is defined by Kitchen.
  #
  # @see https://www.rubydoc.info/gems/test-kitchen/Kitchen/Verifier
  module Verifier
    # The verifier utilizes the {https://www.inspec.io/ InSpec} infrastructure
    # testing framework to verify the behaviour and
    # state of resources in the Pulumi state.
    #
    # === Commands
    #
    # The following command-line commands are provided by the verifier.
    #
    # ==== kitchen verify
    #
    # A Kitchen instance is verified by iterating through the systems and
    # running the associated InSpec controls against the hosts of each system.
    # The outputs of the Pulumi state are retrieved and exposed as attributes
    # to the InSpec controls.
    #
    # ===== Retrieving the Pulumi Output
    #
    #   pulumi stack output -json
    #
    # === Configuration Attributes
    #
    # The configuration attributes of the verifier control the behaviour
    # of the InSpec runner. Within the
    # {http://kitchen.ci/docs/getting-started/kitchen-yml .kitchen.yml},
    # these attributes must be declared in the +verifier+ mapping along with
    # the plugin name.
    #
    #   verifier:
    #     name: pulumi
    #     a_configuration_attribute: some value
    #
    # ==== color
    #
    # {include:Kitchen::Pulumi::ConfigAttribute::Color}
    #
    # ==== fail_fast
    #
    # {include:Kitchen::Pulumi::ConfigAttribute::FailFast}
    #
    # ==== systems
    #
    # {include:Kitchen::Pulumi::ConfigAttribute::Systems}
    #
    # === Ruby Interface
    #
    # This class implements the interface of Kitchen::Configurable which
    # requires the following Reek suppressions:
    # :reek:MissingSafeMethod {
    #  exclude: [ finalize_config!, load_needed_dependencies! ]
    # }
    class Pulumi
      include ::Kitchen::Configurable
      include ::Kitchen::Logging
      include ::Kitchen::Pulumi::ConfigAttribute::Color
      include ::Kitchen::Pulumi::ConfigAttribute::FailFast
      include ::Kitchen::Pulumi::ConfigAttribute::Systems
      include ::Kitchen::Pulumi::Configurable
      @api_version = 2

      attr_reader :inputs, :outputs

      def initialize(configuration = {})
        init_config configuration
        self.inspec_options_mapper = ::Kitchen::Pulumi::InSpecOptionsMapper.new
        self.error_messages = []
        self.inputs = {}
        self.outputs = {}
      end

      # The verifier enumerates through each host of each system and verifies
      # the associated InSpec controls.
      #
      # @example
      #   `kitchen verify suite-name`
      # @param _kitchen_state [::Hash] the mutable instance and verifier state.
      # @raise [::Kitchen::ActionFailed] if result of the action is failure.
      # @return [void]
      def call(_kitchen_state)
        load_variables
        verify_systems
        unless error_messages.empty?
          raise ::Kitchen::ActionFailed, error_messages.join("\n\n")
        end
      rescue ::Kitchen::Pulumi::Error => e
        raise ::Kitchen::ActionFailed, e.message
      end

      # Checks the system and configuration for common errors.
      #
      # @param _kitchen_state [::Hash] the mutable Kitchen instance state.
      # @return [Boolean] false
      # @see https://github.com/test-kitchen/test-kitchen/blob/v1.21.2/lib/kitchen/verifier/base.rb#L85-L91
      def doctor(_kitchen_state)
        false
      end

      private

      attr_accessor :inspec_options_mapper, :error_messages
      attr_writer :inputs, :outputs

      # Raises an error immediately if the `fail_fast` config attribute is set on the
      #   or collects all errors until execution has ended verifier
      #
      # @return [void]
      def handle_error(message:)
        raise ::Kitchen::Pulumi::Error, message if config_fail_fast

        logger.error message
        error_messages.push message
      end

      # Populates the `stack_inputs` and `stack_outputs` with the fully resolved stack
      #   inputs and outputs produced by the appropriate Pulumi commands
      #
      # @return [void]
      def load_variables
        instance.driver.stack_outputs do |outputs:|
          self.outputs.replace(outputs)
        end

        instance.driver.stack_inputs do |inputs:|
          self.inputs.replace(inputs)
        end
      end

      # load_needed_dependencies! loads the InSpec libraries required to verify
      # a Pulumi stack's state.
      #
      # @raise [::Kitchen::ClientError] if loading the InSpec libraries fails.
      # @see https://github.com/test-kitchen/test-kitchen/blob/v1.21.2/lib/kitchen/configurable.rb#L252-L274
      def load_needed_dependencies!
        require 'kitchen/pulumi/inspec'
        require 'kitchen/pulumi/system'
        ::Kitchen::Pulumi::InSpec.logger = logger
      rescue ::LoadError => e
        raise ::Kitchen::ClientError, e.message
      end

      def system_inspec_options(system:)
        inspec_options_mapper.map(
          options: { 'color' => config_color, 'distinct_exit' => false },
          system: system,
        )
      end

      # Runs verification logic of the given system
      #
      # @param system [::Hash] the system to verify
      # @return [void]
      def verify(system:)
        ::Kitchen::Pulumi::System.new(
          mapping: {
            profile_locations: [
              ::File.join(config.fetch(:test_base_path), instance.suite.name),
            ],
          }.merge(system),
        ).verify(
          inputs: inputs,
          inspec_options: system_inspec_options(system: system),
          outputs: outputs,
        )
      rescue StandardError => e
        handle_error message: e.message
      end

      # Runs verification logic for each system defined on the verifier's `systems` config
      #   attribute
      #
      # @return [void]
      def verify_systems
        config_systems.each do |system|
          verify system: system
        end
      end
    end
  end
end
