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
