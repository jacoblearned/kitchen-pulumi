"use strict";
const pulumi = require("@pulumi/pulumi");

const config = new pulumi.Config("test-project");
const bucketName = config.require("bucket_name");

console.log(bucketName);
