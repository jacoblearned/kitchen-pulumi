import * as azure from "@pulumi/azure";
import * as pulumi from "@pulumi/pulumi";

const resourceGroup = new azure.core.ResourceGroup("kitchen-pulumi-rg");
let config = new pulumi.Config("kitchen-pulumi-azure-functions");
let body = config.get("api_response") || "default";

async function handler(context: azure.appservice.Context<azure.appservice.HttpResponse>, request: azure.appservice.HttpRequest) {
    return {
        status: 200,
        headers: {"content-type": "text/plain"},
        body: body,
    };
}

const fn = new azure.appservice.HttpEventSubscription("kitchen-pulumi-function", {
    resourceGroup,
    callback: handler,
});

export let endpoint = fn.url;
