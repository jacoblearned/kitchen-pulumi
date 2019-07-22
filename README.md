# Kitchen-Pulumi

[![Gem](https://img.shields.io/gem/v/kitchen-pulumi.svg)](https://rubygems.org/gems/kitchen-pulumi/)
[![Gem](https://img.shields.io/gem/dt/kitchen-pulumi.svg)](https://rubygems.org/gems/kitchen-pulumi/)
[![Gem](https://img.shields.io/gem/dtv/kitchen-pulumi.svg)](https://rubygems.org/gems/kitchen-pulumi/)
[![CircleCI](https://circleci.com/gh/jacoblearned/kitchen-pulumi/tree/master.svg?style=shield)](https://circleci.com/gh/jacoblearned/kitchen-pulumi/tree/master)
[![Test Coverage](https://api.codeclimate.com/v1/badges/35afd25bac772504e2a0/test_coverage)](https://codeclimate.com/github/jacoblearned/kitchen-pulumi/test_coverage)
[![Maintainability](https://api.codeclimate.com/v1/badges/35afd25bac772504e2a0/maintainability)](https://codeclimate.com/github/jacoblearned/kitchen-pulumi/maintainability)

Kitchen-Pulumi is a collection of [Test-Kitchen](https://kitchen.ci/) plugins for testing [Pulumi](https://www.pulumi.com/)-based cloud infrastructure projects.
With Kitchen-Pulumi you can provision suites of ephemeral test stacks, verify they are in the correct state using [InSpec](https://www.inspec.io/), and tear them down to gain
confidence in your infrastructure code before it hits production.

## Features

Kitchen-Pulumi provides a Kitchen [driver](https://kitchen.ci/docs/drivers/), [provisioner](https://kitchen.ci/docs/provisioners/),
and [verifier](https://kitchen.ci/docs/verifiers/) which collectively support the following features:

* Language-agnostic: Create and test Pulumi stacks in any of their [supported languages](https://www.pulumi.com/docs/reference/languages/).
* Backend-agnostic: Use the Pulumi SaaS backend, a local backend, or your organization's internal backend.
* Configurable: Easily define/override stack config values in your `.kitchen.yml` file for flexible testing across environments or scenarios.
