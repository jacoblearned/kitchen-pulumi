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
    dev-stack-serverless-rest-api  Pulumi  Pulumi       Busser    Ssh        <Not Created>  <None>
    ```

## Project Overview

In our project directory, we have `Pulumi.yaml` which defines a Node.js Pulumi project named `serverless-rest-api-lambda` as well as
`Pulumi.dev.yaml` which defines two configuration values for our `dev` stack:

* `aws:region` - our desired AWS region, `us-east-1`
* `serverless-rest-api-lambda:api_response_text` - the response string that our API will return. For now it will be "default".

Since we're using Node.js, let's download the `@pulumi/pulumi` and `@pulumi/awsx` Node packages that our project depends on as listed in our `package.json`:

```
$ npm install
```

Our infra code is contained in `index.js` and sets up our API with two endpoints: one at `/` that serves the static content of the `www` directory,
and a `/response` endpoint that will return the value of the `api_response_text` we set in our stack config:

```javascript
// Import the [pulumi/aws](https://pulumi.io/reference/pkg/nodejs/@pulumi/aws/index.html) package
const pulumi = require("@pulumi/pulumi");
const awsx = require("@pulumi/awsx");

const config = new pulumi.Config();
const responseText = config.require("api_response_text");

// Create a public HTTP endpoint (using AWS APIGateway)
const endpoint = new awsx.apigateway.API("hello", {
  routes: [

    // Serve static files from the `www` folder (using AWS S3)
    {
      path: "/",
      localPath: "www"
    },

    // Serve a simple REST API on `GET /response` (using AWS Lambda)
    {
      path: "/response",
      method: "GET",
      eventHandler: (req, ctx, cb) => {
        cb(undefined, {
          statusCode: 200,
          body: Buffer.from(
            JSON.stringify({ response: responseText }),
            "utf8"
          ).toString("base64"),
          isBase64Encoded: true,
          headers: { "content-type": "application/json" }
        });
      }
    }
  ]
});

// Export the public URL for the HTTP service
exports.url = endpoint.url;
```

If you create and provision this stack by executing `pulumi up --stack dev`, you can
navigate to the exported URL value in your browser and see the index page of `www/`
along with the response value "default" that we set in the stack config.

Go ahead and destroy the stack for now if you have validated this in your browser:

```text
$ pulumi destroy -y
```

## Our first integration test

For the first iteration of our integration test, we want to use Kitchen-Pulumi to
simply create and destroy the stack infrastructure to ensure both operations are completed without error.

Looking at `.kitchen.yml`, you will see that we have a single suite called `serverless-rest-api`
and a single platform called `dev-stack`. Together this means we have a single [Kitchen instance](https://kitchen.ci/docs/getting-started/instances/)
called `serverless-rest-api-dev-stack` that we can test against. You can verify this using `kitchen list`:

```text
$ bundle exec kitchen list
Instance                       Driver  Provisioner  Verifier  Transport  Last Action    Last Error
serverless-rest-api-dev-stack  Pulumi  Pulumi       Busser    Ssh        <Not Created>  <None>
```

### Driver Configuration

Setting attributes on the driver is how we customize our integration tests.
Currently, we set the driver's `config_file` attribute to the value `Pulumi.dev.yaml`.
This means that the `dev-stack` platform will run tests against a stack named `dev-stack`
using the config values set in `Pulumi.dev.yaml`.

### Creating a Stack

We can create our dev stack by running `kitchen create`:

```text
$ bundle exec kitchen create
-----> Starting Kitchen (v2.3.2)
-----> Creating <serverless-rest-api-dev-stack>...
$$$$$$ Running pulumi login https://api.pulumi.com
       Logged into pulumi.com as <username> (https://app.pulumi.com/<username>)
$$$$$$ Running pulumi stack init dev-stack -C /Users/<username>/OSS/kitchen-pulumi/examples/aws/serverless-rest-api-lambda
       Created stack 'dev-stack'
       Finished creating <serverless-rest-api-dev-stack> (0m2.67s).
-----> Kitchen is finished. (0m3.43s)
```

You can see from the output that `kitchen create` does two things when using Kitchen-Pulumi's driver:

1. It logs in to the Pulumi service.
   By default it will be the SaaS backend but we'll cover how to override this a bit later.
1. It ensures the stack exists by calling `pulumi stack init dev-stack`. If the stack already exists, Kitchen-Pulumi simply continues without error.

### Provisioning and Updating a Stack

We can now provision our stack resources by running `kitchen converge`:

```text
$ bundle exec kitchen converge
-----> Starting Kitchen (v2.2.5)
-----> Converging <serverless-rest-api-dev-stack>...
$$$$$$ Running pulumi login https://api.pulumi.com
       Logged into pulumi.com as <username> (https://app.pulumi.com/<username>)
$$$$$$ Running pulumi up -y -r --show-config -s dev-stack  -C /Path/to/kitchen-pulumi/examples/aws/serverless-rest-api-lambda
       Previewing update (dev-stack):
       Configuration:
           aws:region: us-east-1
           serverless-rest-api-lambda:api_response_text: default

       ...
       <A lot of output from the update preview and from the update execution>
       ...

       Outputs:
           url: "https://abc123fooexample.execute-api.us-east-1.amazonaws.com/stage/"

       Resources:
           + 14 created

       Duration: 19s

       Permalink: https://app.pulumi.com/<username>/serverless-rest-api-lambda/dev-stack/updates/1
       Finished converging <serverless-rest-api-dev-stack> (0m27.39s).
-----> Kitchen is finished. (0m20.31s)
```

Using Kitchen-Pulumi's provisioner, calling `kitchen converge` will call `pulumi up` on the stack set on the driver for each kitchen instance.

You will also see another login to the Pulumi backend. This is because `kitchen` commands could run against the same stack from different
machines or by different users in a variety of invocation order permutations, so Kitchen-Pulumi will
attempt a login anytime a call to the Pulumi CLI is necessary.

If you visit the value of the `url` stack Output, you should see the index page and the "default" API response text.

### Destroying the Stack

Now that we have manually validated our test stack, we can destroy it with `kitchen destroy`:

```text
$ bundle exec kitchen destroy
-----> Starting Kitchen (v2.2.5)
-----> Destroying <serverless-rest-api-dev-stack>...
$$$$$$ Running pulumi login https://api.pulumi.com
       Logged into pulumi.com as <username> (https://app.pulumi.com/<username>)
$$$$$$ Running pulumi destroy -y -r --show-config -s dev-stack -C /Path/to/kitchen-pulumi/examples/aws/serverless-rest-api-lambda
       Previewing destroy (dev-stack):
       Configuration:
           aws:region: us-east-1
           serverless-rest-api-lambda:api_response_text: default

       ...
       <Preview and Destroy output>
       ...

       Resources:
           - 14 deleted

       Duration: 10s

       Permalink: https://app.pulumi.com/<username>/serverless-rest-api-lambda/dev-stack/updates/2
       The resources in the stack have been deleted, but the history and configuration associated with the stack are still maintained.
       If you want to remove the stack completely, run 'pulumi stack rm dev-stack'.
$$$$$$ Running pulumi stack rm --preserve-config -y -s dev-stack -C /Users/<username>/OSS/kitchen-pulumi/examples/aws/serverless-rest-api-lambda
       Stack 'dev-stack' has been removed!
       Finished destroying <serverless-rest-api-dev-stack> (0m20.04s).
-----> Kitchen is finished. (0m23.42s)
```

`kitchen destroy` will run `pulumi destroy` on our stack and then a final `pulumi stack rm` to remove the stack entirely.
We remove the stack at the end to ensure our test stacks are ephemeral and do not clog the Pulumi stack namespace after
we are finished testing. You can verify this by running `pulumi stack ls` to see that the `dev-stack` stack is not listed.

### Summary

So far, we've seen how to
1. Create a stack with `kitchen create`
1. Update a stack with `kitchen converge`
1. Destroy it with `kitchen destroy`

In the next section, we will cover some more advanced stack testing features
like testing multiple stacks, using other backends, overriding stack config values, providing secrets,
and simulating changes in a stack's configuration over time.

## Advanced Test Customization

Our simple test gave us confidence our stack is being provisioned as expected.
Since our stack is only deployed to the us-east-1 region, however, it isn't resilient to regional disasters.
We would like to increase the availability of the service in production by deploying it to multiple
AWS regions. We want to capture this in our integration tests as well to mirror our production environment
as much as possible.

### Adding a West Test Stack

To test our new us-west-2 based stack, we will change our current test platform in `.kitchen.yml` to `dev-east-test`, introduce another platform
called `dev-west-test`, and override the value of the `aws:region` for `dev-west-test` to be `us-west-2` instead of `us-east-1`:

```yaml
# .kitchen.yml

driver:
  name: pulumi

provisioner:
  name: pulumi

suites:
  - name: serverless-rest-api

platforms:
  - name: dev-east-test
    driver:
      config_file: Pulumi.dev.yaml
  - name: dev-west-test
    driver:
      config_file: Pulumi.dev.yaml
      config:
        aws:
          region: us-west-2
```

Let's break down what we changed:

1. We removed the `test_stack_name` driver attribute because Kitchen-Pulumi will use the name of
   the instance by default. So the stacks that will be created for us will be named `serverless-rest-api-dev-east-test` and `serverless-rest-api-dev-west-test`.
1. We set the `config_file` driver attribute for both suites to be `Pulumi.dev.yaml`.
   This allows us to use the same base stack config file for both stacks.
   The value of `config_file` can be any valid YAML file that matches the Pulumi
   stack config file specification.
1. We override the value of the `aws:region` stack config on the `dev-west` stack using the `config`
   driver attribute. The `config` attribute is a map of maps whose top-level keys
   correspond to Pulumi namespaces. The values defined in a `config` driver attribute will
   always take precedence over those defined in an instance's `config_file`.

### Provisioning Multiple Stacks

With this configuration, we can now create two identical test stacks deployed to both us-east-1 and us-west-2:

```
$ bundle exec kitchen converge
-----> Creating <serverless-rest-api-dev-east-test>...
$$$$$$ Running pulumi login https://api.pulumi.com
       Logged into pulumi.com as <username> (https://app.pulumi.com/<username>)
$$$$$$ Running pulumi stack init serverless-rest-api-dev-east-test -C /Users/<username>/OSS/kitchen-pulumi/examples/aws/serverless-rest-api-lambda
       Created stack 'serverless-rest-api-dev-east-test'
       Finished creating <serverless-rest-api-dev-east-test> (0m2.21s).
-----> Converging <serverless-rest-api-dev-east-test>...

       <Update output for east stack>

       Outputs:
           url: "https://y0nh87lz59.execute-api.us-east-1.amazonaws.com/stage/"

       Resources:
           + 14 created

       Duration: 19s

       Permalink: https://app.pulumi.com/<username>/serverless-rest-api-lambda/serverless-rest-api-dev-east-test/updates/1
       Finished converging <serverless-rest-api-dev-east-test> (0m25.91s).
-----> Creating <serverless-rest-api-dev-west-test>...
$$$$$$ Running pulumi login https://api.pulumi.com
       Logged into pulumi.com as <username> (https://app.pulumi.com/<username>)
$$$$$$ Running pulumi stack init serverless-rest-api-dev-west-test -C /Users/<username>/OSS/kitchen-pulumi/examples/aws/serverless-rest-api-lambda
       Created stack 'serverless-rest-api-dev-west-test'
       Finished creating <serverless-rest-api-dev-west-test> (0m1.84s).
-----> Converging <serverless-rest-api-dev-west-test>...
       <Update output for west stack>

       Outputs:
           url: "https://t87sy6zivb.execute-api.us-west-2.amazonaws.com/stage/"

       Resources:
           + 14 created

       Duration: 29s

       Permalink: https://app.pulumi.com/<username>/serverless-rest-api-lambda/serverless-rest-api-dev-west-test/updates/1
       Finished converging <serverless-rest-api-dev-west-test> (0m37.75s).
```

If you visit both of the output URLs, you will see our service is now live in both regions.
Whenever you are ready, destroy both stacks with `bundle exec kitchen destroy`.

### Specifying a Backend

If you're organization has its own internal backend or you would like to use your local machine as a backend, you can tell Kitchen-Pulumi to do so using the `backend` driver attribute. The value of `backend` defaults to the Pulumi SaaS backend, and accepts any valid URL or the keyword `local` for using the local backend.

Note: When using the local backend, you may see stack config files being created. These are created by Pulumi to properly encrypt values and will be removed during `kitchen destroy`.

The following will use a local backend for the west stack and an S3 bucket for the east:

```yaml
# .kitchen.yml

driver:
  name: pulumi

provisioner:
  name: pulumi

suites:
  - name: serverless-rest-api

platforms:
  - name: dev-east-test
    driver:
      backend: s3://my-pulumi-state-bucket
      config_file: Pulumi.dev.yaml
  - name: dev-west-test
    driver:
      backend: local
      config_file: Pulumi.dev.yaml
      config:
        aws:
          region: us-west-2
```

### Providing Secrets

#### Specifying a Secrets Provider

If you would like to use an alternative [secret encryption provider](https://www.pulumi.com/docs/intro/concepts/config/#initializing-a-stack-with-alternative-encryption)
with your test stacks, you can provide a value to the `secrets_provider` driver attribute.

When the dev-stack stack gets created, it will use the specified KMS key to encrypt secrets.

```yaml
# .kitchen.yml
---

driver:
  name: pulumi

provisioner:
  name: pulumi

suites:
  - name: dev-stack
    driver:
      test_stack_name: dev-stack
      config_file: Pulumi.dev.yaml
      secrets_provider: "awskms://1234abcd-12ab-34cd-56ef-1234567890ab?region=us-east-1"

platforms:
  - name: serverless-rest-api
```

#### Overriding Config File Secrets

If you have already set secret values in a stack config file, but would like to test
the stack with a different value for certain secrets without permanently overriding
the stack config file, you can specify a `secrets` map. This driver attribute is similar to the `config` map we used earlier to override the value of `aws:region` in our west test stack.

This can be useful when secrets change between deployment environments or you have
credentials for testing purposes only. The following configuration will set the
`my-project:ssh_key` stack secret to the value of the `TEST_USER_SSH_KEY`
environment variable using Ruby's flexible [ERB templating syntax](https://www.stuartellis.name/articles/erb/) without affecting the existing value of `my-project:ssh_key` defined in `Pulumi.dev.yaml`.

```yaml
# .kitchen.yml
---

driver:
  name: pulumi

provisioner:
  name: pulumi

suites:
  - name: dev-stack
    driver:
      test_stack_name: dev-stack
      config_file: Pulumi.dev.yaml
      secrets:
        my-project:
          ssh_key: <%= ENV['TEST_USER_SSH_KEY'] %>

platforms:
  - name: serverless-rest-api
```

### Testing Stack Changes Over Time

To further test the resolve of your Pulumi project, you may want to test how
existing stacks will react to changes in configuration values after their initial
provisioning. Kitchen-Pulumi allows you to test successive changes to existing
test stacks through the `stack_evolution` driver attribute.

`stack_evolution` takes a list of desired configuration changes as specified using the following three values (at least one must be provided):

  * `config_file` - A valid YAML file to use instead of the config file defined on the top-level `config_file` driver attribute.
  * `config` - A map of values with same structure as the top-level `config` driver attribute. These values are merged with the top-level `config` and any keys specified in both will be overwritten by the `stack_evolution` step's value.
  * `secrets` - A map of secrets with same structure as the top-level `secrets` driver attribute. These values are merged with the top-level `secrets` and any keys specified in both will be overwritten by the `stack_evolution` step's value.

Each item in `stack_evolution` represents an independent stack configuration.
Kitchen-Pulumi will call `pulumi up` on the test stack for each configuration.
The example below will perform the following stack updates on dev-stack when `kitchen converge` runs against it:

1. The initial update using the configuration specified in the top-level `config_file`, `Pulumi.dev.yaml`.
2. If the first update succeeded, the stack will be updated using the configuration specified in `test-cases/second_update_changed_response.yaml`.
3. If the second update succeeded, the stack will be updated using the configuration specified in the top-level config file, `Pulumi.dev.yaml`, but with the
`serverless-rest-api-lambda:api_response_text` and `serverless-rest-api-lambda:db_password` values overridden.

```yaml
# .kitchen.yml

driver:
  name: pulumi

provisioner:
  name: pulumi

suites:
  - name: dev-stack
    driver:
      test_stack_name: dev-stack
      config_file: Pulumi.dev.yaml
      stack_evolution:
        - config_file: test-cases/second_update_changed_response.yaml
        - config:
            serverless-rest-api-lambda:
              api_response_text: third update
          secrets:
            serverless-rest-api-lambda:
              db_password: <%= ENV['NEW_DB_PASSWORD'] %>

platforms:
  - name: serverless-rest-api

```

You can think of the top-level `config_file`, `config`, and `secrets` values as "global" settings for the driver across stack updates, and those specified in
`stack_evolution` as temporary overrides.
