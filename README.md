# ECS EC2 Quick Start

## Summary

A simple example to show how to deploy a Docker image using ECS EC2 via CloudFormation.

This quick start guide contains three `.yaml` CloudFormation template files:

* [`main.yaml`](./main.yaml): The root template for this example
* [`Cluster.yaml`](./Cluster.yaml): Template for setting up the the underlying infrastructure
* [`TaskDefinition.yaml`](./TaskDefinition.yaml): Template for setting up the EC2 Task Definition.

This sample creates a nested stack in CloudFormation. This allows you to update the ECS Task Definition without touching the rest of the underlying infrastructure. After executing the template, it will create the following AWS resources:

* EC2 Instance
  * IAM Instance Profile
    * IAM Role
* ECS Cluster
  * ECS Service
    * EC2 Task Definition
      * Container Definition for `nginx-alphine`

## Create the stack

This CloudFormation stack can be created via AWS CLI with the provided script [`createStack.sh`](./createStack.sh)

### Create a S3 bucket for all the templates

Since our example is using a nested stack, it requires us to have all template files uploaded to a S3 bucket before running them. You can create a new S3 bucket via this command:

```bash
aws s3 mb s3://<YOUR_S3_BUCKET_NAME> --region us-east-1

# Add tags for your S3 bucket
aws s3api put-bucket-tagging --bucket <YOUR_S3_BUCKET_NAME> \
  --tagging 'TagSet=[{Key=tr:environment-type,Value=<YOUR_TR_ENVIRONMENT_TAG>},{Key=tr:financial-identifier,Value=<YOUR_TR_FINANCIAL_IDENTIFIER_TAG>},{Key=tr:application-asset-insight-id,Value=<YOUR_TR_ASSET_INSIGHT_ID_TAG>},{Key=tr:resource-owner,Value=<YOUR_EMAIL_ADDRESS>}]'
```

Check [here](https://docs.aws.amazon.com/AmazonS3/latest/user-guide/create-bucket.html) if you need more help on this.

### Update [`createStack.sh`](./createStack.sh)

[`createStack.sh`](./createStack.sh) provides you an easy way to configure all parameters and launch the template. Before running the script, update the following enviornment variables inside:

```bash
# TR tags
TR_ENV=<YOUR_TR_ENVIRONMENT_TAG>
TR_FINANCIAL_ID=<YOUR_TR_FINANCIAL_IDENTIFIER_TAG>
TR_ASSET_ID=<YOUR_TR_ASSET_INSIGHT_ID_TAG>
TR_OWNER=<YOUR_EMAIL_ADDRESS>

# Cluster Settings
STACK_NAME=<YOUR_CLOUDFORMATION_STACK_NAME>
S3_BUCKET_NAME=<YOUR_S3_BUCKET_NAME>
CLUSTER_NAME=<YOUR_ECS_CLUSTER_NAME>
SERVICE_NAME=<YOUR_ECS_SERVICE_NAME>
TASK_DEFINITION_NAME=<YOUR_ECS_TASK_DEFINITION_NAME>
INSTANCE_TYPE='t2.micro'
IMAGE_ID=<tr-amazon-ecs-optimized-linux_ID>     # AMI ID for tr-amazon-ecs-optimized-linux image
IAM_PROFILE_NAME=<YOUR_IAM_PROFILE_NAME>        # Will be created as part of the stack
VPC_ID=<YOUR_VPC_ID>                            # VPC ID for tr-vpc-1
SUBNET_ID=<PUBLIC_SUBNET_ID>                    # Public subnet ID for tr-vpc-1
```


### Execute the script

```bash
./createStack.sh
```

## Verify the result

Once your stack is created successfully, you can find the public IP for the `nginx-alphine` container from the output of the following command:

```bash
aws cloudformation describe-stacks --stack-name <YOUR_STACK_NAME> --query 'Stacks[0].Outputs'
```

You should get the Nginx Welcome Page if you try to browse `http://<Public_IP>`

### Delete and clean-up the stack

```bash
aws --region us-east-1 cloudformation delete-stack --stack-name <YOUR_STACK_NAME>
```
