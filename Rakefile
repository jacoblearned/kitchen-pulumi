# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'

task default: %I[lint:auto_correct spec]

RuboCop::RakeTask.new(:lint)

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = <<~ARGS
    --format progress \
    --format RspecJunitFormatter \
    --out /tmp/test-results/rspec.xml
  ARGS
end

desc 'Integration tests'
task :integration_test do
  Dir.chdir('spec/support/test-project')
  begin
    sh 'kitchen test'
  ensure
    # Remove intermediate config files
    sh 'rm Pulumi.*.yaml'
  end
end

desc 'Install test project NPM packages'
task :npm_install do
  Dir.chdir('spec/support/test-project')
  sh 'npm i'
end
