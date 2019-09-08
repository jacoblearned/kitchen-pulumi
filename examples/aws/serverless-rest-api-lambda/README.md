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

Looking at `.kitchen.yml`, you will see that we have a single platform called `serverless-rest-api`
and a single suite called `dev-stack`. Together this means we have a single [Kitchen instance](https://kitchen.ci/docs/getting-started/instances/)
called `dev-stack-serverless-rest-api` that we can test against. You can verify this using `kitchen list`:

```text
$ bundle exec kitchen list
Instance                       Driver  Provisioner  Verifier  Transport  Last Action    Last Error
dev-stack-serverless-rest-api  Pulumi  Pulumi       Busser    Ssh        <Not Created>  <None>
```

### Driver Configuration

Setting attributes on the driver is how we customize our integration tests.
Currently, we set the driver's `config_file` attribute to the value `Pulumi.dev.yaml`.
This means that the `dev-stack` suite will run tests against a stack named `dev-stack`
using the config values set in `Pulumi.dev.yaml`.

### Creating a Stack

We can create our dev stack by running `kitchen create`:

```text
$ bundle exec kitchen create
-----> Starting Kitchen (v2.3.2)
-----> Creating <dev-stack-serverless-rest-api>...
$$$$$$ Running pulumi login https://api.pulumi.com
       Logged into pulumi.com as <username> (https://app.pulumi.com/<username>)
$$$$$$ Running pulumi stack init dev-stack -C /Users/<username>/OSS/kitchen-pulumi/examples/aws/serverless-rest-api-lambda
       Created stack 'dev-stack'
       Finished creating <dev-stack-serverless-rest-api> (0m2.67s).
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
-----> Converging <dev-stack-serverless-rest-api>...
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
       Finished converging <dev-stack-serverless-rest-api> (0m27.39s).
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
-----> Destroying <dev-stack-serverless-rest-api>...
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
       Finished destroying <dev-stack-serverless-rest-api> (0m20.04s).
-----> Kitchen is finished. (0m23.42s)
```

`kitchen destroy` will run `pulumi destroy` on our stack and then a final `pulumi stack rm` to remove the stack entirely.
We remove the stack at the end to ensure our test stacks are ephemeral and do not clog the Pulumi stack namespace after
we are finished testing. You can verify this by running `pulumi stack ls` to see that the `dev-stack` stack is not listed.

### Summary

So far we've seen how to
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

To test our new us-west-2 based stack, we will change our current test suite in `.kitchen.yml` to `dev-east`, introduce another suite
called `dev-west`, and override the value of the `aws:region` for `dev-west` to be `us-west-2` instead of `us-east-1`:

```yaml
# .kitchen.yml

driver:
  name: pulumi

provisioner:
  name: pulumi

suites:
  - name: dev-east-test
    driver:
      config_file: Pulumi.dev.yaml
  - name: dev-west-test
    driver:
      config_file: Pulumi.dev.yaml
      config:
        aws:
          region: us-west-2

platforms:
  - name: serverless-rest-api
```

Let's break down what we changed:

1. We removed the `test_stack_name` driver attribute because Kitchen-Pulumi will use the name of
   the instance by default. So the stacks that will be created for us will be named `dev-east-test-serverless-rest-api` and `dev-west-test-serverless-rest-api`.
1. We set the `config_file` driver attribute for both suites to be `Pulumi.dev.yaml`.
   This allows us to use the same base config file for both stacks.
   The value of `config_file` can be any valid YAML file that matches the Pulumi
   stack config file specification.
1. We override the value of the `aws:region` stack config on the `dev-west` stack using the `config`
   driver attribute. The `config` attribute is a map of maps whose top-level keys
   correspond to Pulumi namespaces. The values defined in a `config` driver attribute will
   always take precedence over those defined in an instance's `config_file`.
