#!/bin/bash

# Input variables
layer_name="question_allocator_layer"
description="update lambda layer"
s3_bucket="question_allocator-poc"
zip_file_key="lambda/layer.zip"
function_name="question_allocator_lambda"
region="us-east-1"
account_id="975049981490"
local_zip_file="lambda/layer.zip"

# Upload ZIP file to S3
mkdir python
pip3 install --platform manylinux2014_x86_64 -t python/ --python-version 3.12 --only-binary=:all: -r ../lambda/layer/requirements.txt
zip -r "$local_zip_file" python/
aws s3 cp "$local_zip_file" "s3://$s3_bucket/$zip_file_key"
echo "ZIP file uploaded to S3 bucket $s3_bucket with key $zip_file_key"

# Create a new version of the Lambda layer
layer_version=$(aws lambda publish-layer-version \
    --layer-name "$layer_name" \
    --description "$description" \
    --content S3Bucket="$s3_bucket",S3Key="$zip_file_key" \
    --query Version \
    --output text)
echo "New version of the layer created: $layer_version"

# Update Lambda function to use the new layer version
aws lambda update-function-configuration \
    --function-name "$function_name" \
    --layers "arn:aws:lambda:$region:$account_id:layer:$layer_name:$layer_version"
echo "Lambda function $function_name updated to use layer version $layer_version"
