#!/bin/bash

[ ! -z "$DEBUG" ] && set -x

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


# Validate templates
for yml in *.yaml
do
  aws cloudformation validate-template --template-body file://${PWD}/${yml} > /dev/null
  if [ $? -ne 0 ]; then
    echo ""
    echo "Error: Template Validation Error in $yml"
    echo ""
    exit 1
  fi
done

# Check AWS connection
aws s3 ls "s3://${S3_BUCKET_NAME}" > /dev/null
if [ $? -ne 0 ]; then
  echo ""
  echo "Error! Unable to access S3 bucket: ${S3_BUCKET_NAME}"
  echo ""
  exit 1
fi

# Upload the YAML templates to S3
aws s3 sync --exclude="*" --include="*.yaml" . "s3://${S3_BUCKET_NAME}"

# Create the stack
aws cloudformation create-stack --stack-name ${STACK_NAME} \
  --template-url "https://s3.amazonaws.com/${S3_BUCKET_NAME}/main.yaml" \
  --capabilities CAPABILITY_NAMED_IAM \
  --parameters ParameterKey=S3BucketName,ParameterValue=${S3_BUCKET_NAME} \
               ParameterKey=ClusterName,ParameterValue=${CLUSTER_NAME} \
               ParameterKey=ServiceName,ParameterValue=${SERVICE_NAME} \
               ParameterKey=TaskDefinitionName,ParameterValue=${TASK_DEFINITION_NAME} \
               ParameterKey=VpcId,ParameterValue=\"${VPC_ID}\" \
               ParameterKey=SubnetId,ParameterValue=${SUBNET_ID} \
               ParameterKey=IAMProfileName,ParameterValue=${IAM_PROFILE_NAME} \
               ParameterKey=ImageId,ParameterValue=${IMAGE_ID} \
               ParameterKey=InstanceType,ParameterValue=${INSTANCE_TYPE} \
               ParameterKey=Environment,ParameterValue=${TR_ENV} \
               ParameterKey=FinancialIdentifier,ParameterValue=${TR_FINANCIAL_ID} \
               ParameterKey=ApplicationAssetInsightId,ParameterValue=${TR_ASSET_ID} \
               ParameterKey=ResourceOwner,ParameterValue=${TR_OWNER} \
  --tags Key=tr:environment-type,Value=${TR_ENV} \
         Key=tr:financial-identifier,Value=${TR_FINANCIAL_ID} \
         Key=tr:application-asset-insight-id,Value=${TR_ASSET_ID} \
         Key=tr:resource-owner,Value=${TR_OWNER}

echo "Waiting for Stack Creation complete..."
aws cloudformation wait stack-create-complete --stack-name ${STACK_NAME}
echo "Done!"

# # Clean up stack
# aws cloudformation delete-stack --stack-name ${STACK_NAME}
# echo "Waiting for Stack Deletion complete..."
# aws cloudformation wait stack-delete-complete --stack-name ${STACK_NAME}
# echo "Done!"
