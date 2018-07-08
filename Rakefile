# frozen_string_literal: true

require 'rspec/core/rake_task'
require 'rubocop/rake_task'

task default: [:lint, :spec]

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new(:lint)
