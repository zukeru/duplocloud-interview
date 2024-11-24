#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Function to display usage
usage() {
  echo "Usage: $0 --bucket-name <bucket-name> --table-name <table-name> --region <aws-region>"
  exit 1
}

# Parse arguments
while [[ "$#" -gt 0 ]]; do
  case $1 in
    --bucket-name) BUCKET_NAME="$2"; shift ;;
    --table-name) TABLE_NAME="$2"; shift ;;
    --region) REGION="$2"; shift ;;
    *) echo "Unknown parameter passed: $1"; usage ;;
  esac
  shift
done

# Check if required parameters are provided
if [[ -z "$BUCKET_NAME" || -z "$TABLE_NAME" || -z "$REGION" ]]; then
  echo "Error: Missing required parameters."
  usage
fi

# Empty the S3 bucket before deletion
echo "Emptying S3 bucket: $BUCKET_NAME"
aws s3 rm s3://"$BUCKET_NAME" --recursive

# Delete S3 bucket
echo "Deleting S3 bucket: $BUCKET_NAME"
aws s3api delete-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$REGION"

# Delete DynamoDB table
echo "Deleting DynamoDB table: $TABLE_NAME"
aws dynamodb delete-table \
  --table-name "$TABLE_NAME" \
  --region "$REGION"

echo "Resources deleted successfully."
