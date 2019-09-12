# Kitchen-Pulumi

[![Gem](https://img.shields.io/gem/v/kitchen-pulumi.svg)](https://rubygems.org/gems/kitchen-pulumi/)
[![Gem](https://img.shields.io/gem/dt/kitchen-pulumi.svg)](https://rubygems.org/gems/kitchen-pulumi/)
[![Gem](https://img.shields.io/gem/dtv/kitchen-pulumi.svg)](https://rubygems.org/gems/kitchen-pulumi/)
[![CircleCI](https://circleci.com/gh/jacoblearned/kitchen-pulumi/tree/master.svg?style=shield)](https://circleci.com/gh/jacoblearned/kitchen-pulumi/tree/master)
[![Test Coverage](https://api.codeclimate.com/v1/badges/35afd25bac772504e2a0/test_coverage)](https://codeclimate.com/github/jacoblearned/kitchen-pulumi/test_coverage)
[![Maintainability](https://api.codeclimate.com/v1/badges/35afd25bac772504e2a0/maintainability)](https://codeclimate.com/github/jacoblearned/kitchen-pulumi/maintainability)

Kitchen-Pulumi is a collection of [Test-Kitchen](https://kitchen.ci/) plugins for testing [Pulumi](https://www.pulumi.com/)-based cloud infrastructure projects
under the [test-driven infrastructure](https://www.arresteddevops.com/tdi/) paradigm.
With Kitchen-Pulumi you can provision ephemeral test stacks, verify they are in a desired state using [InSpec](https://www.inspec.io/), and tear them down to gain
confidence in your infrastructure code before it hits production.

## Features

Kitchen-Pulumi provides a Kitchen [driver](https://kitchen.ci/docs/drivers/), [provisioner](https://kitchen.ci/docs/provisioners/),
and [verifier](https://kitchen.ci/docs/verifiers/) which collectively support the following features:

* **Language-agnostic**: Create and test Pulumi stacks in any of their [supported languages](https://www.pulumi.com/docs/reference/languages/).
* **Backend-agnostic**: Use the Pulumi SaaS backend, a local backend, or your organization's internal backend.
* **Configurable**: Easily define/override stack config values in your `.kitchen.yml` file for flexible testing across environments or scenarios.
* **Test changes over time**: Simulate changes in stack config values over time to test how your infrastructure reacts to ever-shifting user-provided values.
* **Custom state verification**: Code any validation logic you desire, provided it can be ran within an [InSpec profile](https://www.inspec.io/docs/reference/profiles/).

If there's a feature you would like to see in Kitchen-Pulumi, please create an issue with the suggested feature and its intended use case.

## Installation

Kitchen-Pulumi is compatible with Ruby 2.4 and above. Add this line to your application's Gemfile:

```ruby
# Gemfile

gem 'kitchen-pulumi'
```

And then execute:

```
$ bundle
```

Or install it yourself as:

```
$ gem install kitchen-pulumi
```

## Quick Start / Tutorial

Check out the [serverless-rest-api-lambda example](examples/aws/serverless-rest-api-lambda) and follow the instructions in its `README`.

## Usage

TODO: Write usage instructions here

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.
To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are always welcome on GitHub at https://github.com/[USERNAME]/kitchen-pulumi. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Kitchen-Pulumi’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/kitchen-pulumi/blob/master/CODE_OF_CONDUCT.md).

