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

# Empty the S3 bucket, including all versions
echo "Emptying S3 bucket (including all versions): $BUCKET_NAME"

# Initialize variables for pagination
NEXT_KEY_MARKER=""
NEXT_VERSION_ID_MARKER=""

while true; do
  if [[ -z "$NEXT_KEY_MARKER" ]]; then
    VERSIONS_RESPONSE=$(aws s3api list-object-versions --bucket "$BUCKET_NAME" --output json)
  else
    VERSIONS_RESPONSE=$(aws s3api list-object-versions --bucket "$BUCKET_NAME" --output json --key-marker "$NEXT_KEY_MARKER" --version-id-marker "$NEXT_VERSION_ID_MARKER")
  fi

  # Extract versions and delete markers
  OBJECTS=$(echo "$VERSIONS_RESPONSE" | jq '[.Versions[]?, .DeleteMarkers[]?] | map({Key:.Key, VersionId:.VersionId})')

  # Check if there are any objects to delete
  if [ "$(echo "$OBJECTS" | jq 'length')" -eq "0" ]; then
    echo "No more objects to delete."
    break
  fi

  # Delete objects
  echo "Deleting $(echo "$OBJECTS" | jq 'length') objects..."
  aws s3api delete-objects --bucket "$BUCKET_NAME" --delete "$(echo "$OBJECTS" | jq -c '{Objects: .}')"

  # Check for more objects
  IS_TRUNCATED=$(echo "$VERSIONS_RESPONSE" | jq -r '.IsTruncated')
  if [ "$IS_TRUNCATED" != "true" ]; then
    break
  fi

  # Set markers for next request
  NEXT_KEY_MARKER=$(echo "$VERSIONS_RESPONSE" | jq -r '.NextKeyMarker')
  NEXT_VERSION_ID_MARKER=$(echo "$VERSIONS_RESPONSE" | jq -r '.NextVersionIdMarker')
done

# Delete S3 bucket
echo "Deleting S3 bucket: $BUCKET_NAME"
aws s3api delete-bucket --bucket "$BUCKET_NAME" --region "$REGION"

# Delete DynamoDB table
echo "Deleting DynamoDB table: $TABLE_NAME"
aws dynamodb delete-table --table-name "$TABLE_NAME" --region "$REGION"

echo "Resources deleted successfully."
