# Azure Example - Azure Functions & Stack Evolution

This directory contains an example of using kitchen-pulumi in Azure and making use of
the `stack_evolution` driver config to simulate stack configuration changes over time.

This project creates an [Azure Functions](https://docs.microsoft.com/en-us/azure/azure-functions/functions-overview)
Function App with an HTTP event subscription to serve as a simple endpoint we can spin up and hit.
We'll change the configuration of the project a couple times and then test that the final state of
the infrastructure matches the final configuration values we specify in our `.kitchen.yml`.

## Getting Started

To create this stack you'll need an Azure subscription and a local Azure session:

```
$ az login
```

Then install project dependencies and kitchen-pulumi if you haven't already:

```
$ bundle install kitchen-pulumi
$ npm i
```

## Changing the stack over time

In `index.ts`, we set the body of our function's response to be the value of the
`api_response` stack configuration value or `default` if it isn't set:

```typescript
import * as azure from "@pulumi/azure";
import * as pulumi from "@pulumi/pulumi";

let config = new pulumi.Config("kitchen-pulumi-azure-functions");
let body = config.get("api_response") || "default";

async function handler(context: azure.appservice.Context<azure.appservice.HttpResponse>, request: azure.appservice.HttpRequest) {
    return {
        status: 200,
        headers: {"content-type": "text/plain"},
        body: body,
    };
}
```

To see how the project would perform if we decide to change the API response,
we use the `stack_evolution` driver config to specify two subsequent updates to the stack

```yaml
# .kitchen.yml

driver:
  name: pulumi

provisioner:
  name: pulumi

verifier:
  name: pulumi
  systems:
    - name: default
      backend: local

suites:
  - name: dev-stack
    driver:
      test_stack_name: dev-stack
      config_file: Pulumi.dev.yaml
      stack_evolution:
        - config:
            kitchen-pulumi-azure-functions:
              api_response: hello
        - config:
            kitchen-pulumi-azure-functions:
              api_response: world

platforms:
  - name: azure-functions-test
```

Now when we run `bundle exec kitchen converge`, we perform three calls to `pulumi up` for the `dev-stack`:

1. The first stack creation to create the stack with the initial config. The `api_response` will be `default`.
2. The second update to change the `api_response` to `hello`.
3. The final update to change the `api_response` to `world`.

```
$ bundle exec kitchen converge
-----> Starting Test Kitchen (v2.10.0)
-----> Converging <dev-stack-azure-functions-test>...
$$$$$$ Running pulumi login https://api.pulumi.com
       Logged in to pulumi.com as <user> (https://app.pulumi.com/<account>)
$$$$$$ Running pulumi up -y -r --show-config -s dev-stack -C /path/to/kitchen-pulumi/examples/azure/functions --config-file /var/folders/gx/d77kc9711jv_1bbc_15v3zyw0000gn/T/kitchen-pulumi20210203-51742-1vjon8i.yaml
       Previewing update (dev-stack)

       View Live: https://app.pulumi.com/<account>/kitchen-pulumi-azure-functions/dev-stack/previews/a2249513-8441-403f-9d15-f2beba7099fc

       Configuration:
           azure:environment: public
           azure:location: eastus2

        +  pulumi:pulumi:Stack kitchen-pulumi-azure-functions-dev-stack create
        +  azure:appservice:HttpEventSubscription kitchen-pulumi-function create
        +  azure:core:ResourceGroup kitchen-pulumi-rg create
        +  azure:storage:Account kitchenpulumifun create
        +  azure:appservice:Plan kitchen-pulumi-function create
        +  azure:storage:Container kitchen-pulumi-function create
        +  azure:storage:Blob kitchen-pulumi-function create
        +  azure:appservice:FunctionApp kitchen-pulumi-function create
        +  pulumi:pulumi:Stack kitchen-pulumi-azure-functions-dev-stack create

       Resources:
           + 8 to create

       Updating (dev-stack)

       View Live: https://app.pulumi.com/<account>/kitchen-pulumi-azure-functions/dev-stack/updates/1

       Configuration:
           azure:environment: public
           azure:location: eastus2

        ...

       Outputs:
           endpoint: "https://kitchen-pulumi-function<12345>.azurewebsites.net/api/kitchen-pulumi-function"

       Resources:
           + 8 created

       Duration: 1m25s

$$$$$$ Running pulumi config set  -s dev-stack -C /path/to/kitchen-pulumi/examples/azure/functions --config-file /var/folders/gx/d77kc9711jv_1bbc_15v3zyw0000gn/T/kitchen-pulumi20210203-51742-1vjon8i.yaml kitchen-pulumi-azure-functions:api_response "hello"
$$$$$$ Running pulumi up -y -r --show-config -s dev-stack -C /path/to/kitchen-pulumi/examples/azure/functions --config-file /var/folders/gx/d77kc9711jv_1bbc_15v3zyw0000gn/T/kitchen-pulumi20210203-51742-1vjon8i.yaml
       Previewing update (dev-stack)

       View Live: https://app.pulumi.com/<account>/kitchen-pulumi-azure-functions/dev-stack/previews/163e9662-e091-4bdc-9cbe-6e0e1a3d9988

       Configuration:
           azure:environment: public
           azure:location: eastus2
           kitchen-pulumi-azure-functions:api_response: hello

           ...

        ++ azure:storage:Blob kitchen-pulumi-function create replacement [diff: ~source]
        +- azure:storage:Blob kitchen-pulumi-function replace [diff: ~source]
        ~  azure:appservice:FunctionApp kitchen-pulumi-function update [diff: ~appSettings]
        -- azure:storage:Blob kitchen-pulumi-function delete original [diff: ~source]
           pulumi:pulumi:Stack kitchen-pulumi-azure-functions-dev-stack

       Resources:
           ~ 1 to update
           +-1 to replace
           2 changes. 6 unchanged

       Updating (dev-stack)

       View Live: https://app.pulumi.com/<account>/kitchen-pulumi-azure-functions/dev-stack/updates/2

       Configuration:
           azure:environment: public
           azure:location: eastus2
           kitchen-pulumi-azure-functions:api_response: hello

        ...

       Outputs:
           endpoint: "https://kitchen-pulumi-function<12345>.azurewebsites.net/api/kitchen-pulumi-function"

       Resources:
           ~ 1 updated
           +-1 replaced
           2 changes. 6 unchanged

       Duration: 31s

$$$$$$ Running pulumi config set  -s dev-stack -C /path/to/kitchen-pulumi/examples/azure/functions --config-file /var/folders/gx/d77kc9711jv_1bbc_15v3zyw0000gn/T/kitchen-pulumi20210203-51742-1vjon8i.yaml kitchen-pulumi-azure-functions:api_response "world"
$$$$$$ Running pulumi up -y -r --show-config -s dev-stack -C /path/to/kitchen-pulumi/examples/azure/functions --config-file /var/folders/gx/d77kc9711jv_1bbc_15v3zyw0000gn/T/kitchen-pulumi20210203-51742-1vjon8i.yaml
       Previewing update (dev-stack)

       View Live: https://app.pulumi.com/<account>/kitchen-pulumi-azure-functions/dev-stack/previews/6970a149-c1ef-44a7-9ef0-f227bf4797c8

       Configuration:
           azure:environment: public
           azure:location: eastus2
           kitchen-pulumi-azure-functions:api_response: world

        ...

       Resources:
           ~ 1 to update
           +-1 to replace
           2 changes. 6 unchanged

       Updating (dev-stack)

       View Live: https://app.pulumi.com/<account>/kitchen-pulumi-azure-functions/dev-stack/updates/3

       Configuration:
           azure:environment: public
           azure:location: eastus2
           kitchen-pulumi-azure-functions:api_response: world

        ...

       Outputs:
           endpoint: "https://kitchen-pulumi-function<12345>.azurewebsites.net/api/kitchen-pulumi-function"

       Resources:
           ~ 1 updated
           +-1 replaced
           2 changes. 6 unchanged

       Duration: 29s

       Finished converging <dev-stack-azure-functions-test> (3m18.29s).
-----> Test Kitchen is finished. (3m20.55s)
```

## Testing Final State

We can now run `bundle exec kitchen verify` to test that the api is serving `world` as the final state
by adding a simple Inspec control to the project:


```yaml
# test/integration/dev-stack/inspec.yml
name: dev-stack     # Same name as suite in .kitchen.yml
```

```ruby
# test/integration/dev-stack/controls/verify.rb

control "integration test" do
  describe http(input('endpoint')) do
    its ('body') { should eq input("kitchen-pulumi-azure-functions:api_response")}
  end
end
```

When we run `bundle exec kitchen verify`, kitchen-pulumi will evolve the stack configuration used for
the final update call in `converge` available as [Inspec inputs](https://docs.chef.io/inspec/inputs/) for
you to use in tests.

```
$ bundle exec kitchen verify
-----> Starting Test Kitchen (v2.10.0)
-----> Setting up <dev-stack-azure-functions-test>...
       Finished setting up <dev-stack-azure-functions-test> (0m0.00s).
-----> Verifying <dev-stack-azure-functions-test>...
$$$$$$ Running pulumi stack -C /path/to/kitchen-pulumi/examples/azure/functions -s dev-stack output -j
       {
         "endpoint": "https://kitchen-pulumi-function<12345>.azurewebsites.net/api/kitchen-pulumi-function"
       }
$$$$$$ Running pulumi login https://api.pulumi.com
       Logged in to pulumi.com as <user> (https://app.pulumi.com/<account>)
$$$$$$ Running pulumi config set  -s dev-stack -C /path/to/kitchen-pulumi/examples/azure/functions --config-file /var/folders/gx/d77kc9711jv_1bbc_15v3zyw0000gn/T/kitchen-pulumi20210203-52198-6tp6sd.yaml kitchen-pulumi-azure-functions:api_response "hello"
$$$$$$ Running pulumi config set  -s dev-stack -C /path/to/kitchen-pulumi/examples/azure/functions --config-file /var/folders/gx/d77kc9711jv_1bbc_15v3zyw0000gn/T/kitchen-pulumi20210203-52198-6tp6sd.yaml kitchen-pulumi-azure-functions:api_response "world"
$$$$$$ Running pulumi config -C /path/to/kitchen-pulumi/examples/azure/functions -s dev-stack --config-file /var/folders/gx/d77kc9711jv_1bbc_15v3zyw0000gn/T/kitchen-pulumi20210203-52198-6tp6sd.yaml -j
       {
         "azure:environment": {
           "value": "public",
           "secret": false
         },
         "azure:location": {
           "value": "eastus2",
           "secret": false
         },
         "kitchen-pulumi-azure-functions:api_response": {
           "value": "world",
           "secret": false
         }
       }

Profile: dev-stack
Version: (not specified)
Target:  local://

  ✔  integration test: HTTP GET on https://kitchen-pulumi-function<12345>.azurewebsites.net/api/kitchen-pulumi-function
     ✔  HTTP GET on https://kitchen-pulumi-function<12345>.azurewebsites.net/api/kitchen-pulumi-function body is expected to eq "world"


Profile Summary: 1 successful control, 0 control failures, 0 controls skipped
Test Summary: 1 successful, 0 failures, 0 skipped
       Finished verifying <dev-stack-azure-functions-test> (0m5.49s).
-----> Test Kitchen is finished. (0m7.93s)

```


## Clean up

FInally we can delete the stack after testing:

```
$ bundle exec kitchen destroy
```
