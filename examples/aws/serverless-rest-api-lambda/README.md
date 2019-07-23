# Testing a Lambda-based Serverless REST API

This Pulumi project manages a simple serverless REST API that is tested with Kitchen-Pulumi.
This project serves as a good tutorial on Kitchen-Pulumi's feature set.

## Setup Kitchen-Pulumi

If you don't have the Pulumi CLI installed, please install it before continuing.
You can download it following [these instructions](https://www.pulumi.com/docs/reference/install/).
Additionally, ensure you have active [AWS credentials](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
as this tutorial will create live resources in your AWS account.

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

1. Ensure your setup looks good:

    ```text
    $ bundle exec kitchen list
    Instance                       Driver  Provisioner  Verifier  Transport  Last Action    Last Error
    dev-stack-serverless-rest-api  Pulumi  Pulumi       Pulumi    Ssh        <Not Created>  <None>
    ```

## Project Overview

In our project directory, we have `Pulumi.yaml` which defines a Pulumi project named `serverless-rest-api-lambda` as well as
`Pulumi.dev.yaml` which defines two configuration values for our `dev` stack:

* `aws:region` - our desired AWS region, `us-east-1`
* `serverless-rest-api-lambda:api_response_text` - the response string that our API will return. For now it will be "default".
