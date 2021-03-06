# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'kitchen/pulumi/version'

desc = <<~DESC
  Kitchen-Pulumi makes it easy to add integration tests \
  to Pulumi-based infrastructure projects.
DESC

::Gem::Specification.new do |spec|
  spec.name = 'kitchen-pulumi'
  spec.version = ::Kitchen::Pulumi::VERSION
  spec.authors = ['Jacob Learned']
  spec.email = ['jacobmlearned@gmail.com']
  spec.homepage = 'https://github.com/jacoblearned/kitchen-pulumi'
  spec.summary = 'Test-Kitchen plugins for Pulumi projects'
  spec.files = Dir.glob('{lib/**/*.rb,lib/**/*.yml,LICENSE,README.md}')
  spec.license = 'MIT'
  spec.description = desc
  spec.metadata['yard.run'] = 'yri'
  spec.required_ruby_version = '>= 2.6'

  spec.add_development_dependency 'guard', '~> 2.14'
  spec.add_development_dependency 'guard-rspec', '~> 4.7'
  spec.add_development_dependency 'pry', '~> 0.13'
  spec.add_development_dependency 'pry-byebug', '~> 3.8'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.7'
  spec.add_development_dependency 'rspec-json_expectations', '~> 2.1'
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.3'
  spec.add_development_dependency 'rubocop', '~> 1.10'
  spec.add_development_dependency 'rubocop-rake', '~> 0.5'
  spec.add_development_dependency 'rubocop-rspec', '~> 2.1'
  spec.add_development_dependency 'simplecov', '~> 0.21'
  spec.add_development_dependency 'yard', '~> 0.9'

  spec.add_dependency 'logger', '~> 1.2'

  spec.add_runtime_dependency 'dry-types', '~> 0.13'
  spec.add_runtime_dependency 'dry-validation', '~> 0.12'
  spec.add_runtime_dependency 'inspec', '>= 3', '< 5'
  spec.add_runtime_dependency 'json', '>= 2.1', '< 2.6'
  spec.add_runtime_dependency 'mixlib-shellout', '>= 2.3', '< 4.0'
  spec.add_runtime_dependency 'test-kitchen', '>= 1.22', '< 3.0'
end
