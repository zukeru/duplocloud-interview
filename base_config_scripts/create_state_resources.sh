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

# Create S3 bucket
echo "Creating S3 bucket: $BUCKET_NAME in region: $REGION"
aws s3api create-bucket \
  --bucket "$BUCKET_NAME" \
  --region "$REGION" \
  --create-bucket-configuration LocationConstraint="$REGION"

# Enable versioning on the S3 bucket
echo "Enabling versioning on S3 bucket: $BUCKET_NAME"
aws s3api put-bucket-versioning \
  --bucket "$BUCKET_NAME" \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
echo "Creating DynamoDB table: $TABLE_NAME in region: $REGION"
aws dynamodb create-table \
  --table-name "$TABLE_NAME" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION"

echo "Resources created successfully."
echo "S3 Bucket Name: $BUCKET_NAME"
echo "DynamoDB Table Name: $TABLE_NAME"
