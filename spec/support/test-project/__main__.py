import pulumi
from pulumi_aws import s3

config = pulumi.Config('test-project')
bucket_name = config.require('bucket_name')

# Create an AWS resource (S3 Bucket)
bucket = s3.Bucket(bucket_name)
