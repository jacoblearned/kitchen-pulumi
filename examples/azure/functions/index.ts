import * as azure from "@pulumi/azure";

const resourceGroup = new azure.core.ResourceGroup("kitchen-pulumi-rg");

async function handler(context: azure.appservice.Context<azure.appservice.HttpResponse>, request: azure.appservice.HttpRequest) {
    return {
        status: 200,
        headers: {
            "content-type": "text/plain",
        },
        body: "integration test",
    };
}

const fn = new azure.appservice.HttpEventSubscription("fn", {
    resourceGroup,
    callback: handler,
});

export let endpoint = fn.url;
