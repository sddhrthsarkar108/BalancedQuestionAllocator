#!/bin/bash

# Input variables
s3_bucket="question_allocator-poc"
zip_file_key="lambda/handler.zip"
function_name="question_allocator_lambda"
local_zip_file="lambda/handler.zip"

# Upload ZIP file to S3
pushd ../lambda/handler
zip -r ../../infrastructure/lambda/handler.zip *
popd
aws s3 cp "$local_zip_file" "s3://$s3_bucket/$zip_file_key"
echo "ZIP file uploaded to S3 bucket $s3_bucket with key $zip_file_key"

# Update Lambda function to use the new code
aws lambda update-function-code \
    --function-name "$function_name" \
    --s3-bucket "$s3_bucket" \
    --s3-key "$zip_file_key" \
    > /dev/null 2>&1
echo "Lambda function $function_name updated to use new code"

max_retries=3
current_retry=0

# Check update status and retry if in progress
while true; do
    update_status=$(aws lambda get-function --function-name "$function_name" --query 'Configuration.LastUpdateStatus' --output text)
    
    # Check if update is completed
    if [ "$update_status" = "Successful" ]; then
        echo "Lambda function code update completed successfully"
        break
    elif [ "$update_status" = "InProgress" ]; then
        if [ "$current_retry" -lt "$max_retries" ]; then
            echo "Update is still in progress. Retrying..."
            sleep 10  # Wait for some time before retrying
            ((current_retry++))
        else
            echo "Maximum retries exceeded. Update still in progress."
            break
        fi
    else
        echo "Lambda function code update failed."
        break
    fi
done
