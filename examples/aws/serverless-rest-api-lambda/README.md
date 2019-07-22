# Testing a Lambda-based Serverless REST API

This Pulumi project manages a simple serverless REST API that is tested with Kitchen-Pulumi.
This project serves as a good tutorial on Kitchen-Pulumi's feature set.

## Setup

If you don't have the Pulumi CLI installed, please install it before continuing. You can download it following [these instructions](https://www.pulumi.com/docs/reference/install/).

1. To get started, clone this repository and navigate to this directory:

    ```text
    $ git clone https://github.com/jacoblearned/kitchen-pulumi
    $ cd kitchen-pulumi/examples/aws/serverless-rest-api-lambda
    ```

1. Create a `Gemfile` and add kitchen-pulumi to your dependencies.
    If you don't have [Bundler](https://bundler.io/) installed, go ahead and install that as well:

    ```text
    $ gem install bundler
    $ touch Gemfile
    ```

    ```ruby
    # Gemfile

    gem 'kitchen-pulumi', require: false, group: :test
    ```

1. Install your dependencies with Bundler:

    ```text
    $ bundle install
    ```

##
