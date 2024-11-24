```markdown
# Create Terraform State Resources

This guide outlines how to create resources for managing Terraform state, including an S3 bucket for state storage and a DynamoDB table for state locking.

---

## Prerequisites

### 1. AWS CLI Installed
Ensure you have the AWS CLI installed and configured:
- [AWS CLI Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)
- [AWS CLI Configuration Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html)

### 2. Execution Permission
Ensure the script has execution permissions:
```bash
chmod +x create_state_resources.sh
```

### 3. IAM Permissions
The following AWS IAM permissions are required:
- `s3:CreateBucket`
- `s3:PutBucketVersioning`
- `dynamodb:CreateTable`

---

## Usage

Run the `create_state_resources.sh` script with the necessary parameters:

```bash
./create_state_resources.sh --bucket-name dupulo-cloud-interview --table-name dupulo-cloud-interview --region us-west-2
```

### Parameters:
- **`--bucket-name`**: The globally unique name for the S3 bucket.
- **`--table-name`**: The name for the DynamoDB table.
- **`--region`**: The AWS region where resources will be created.

### Example:
```bash
./create_state_resources.sh --bucket-name dupulo-cloud-interview --table-name dupulo-cloud-interview --region us-west-2
```

---

## Actions Performed

1. **S3 Bucket Creation**:
   - Creates an S3 bucket in the specified region.
   - Enables versioning on the bucket (a best practice for Terraform state).

2. **DynamoDB Table Creation**:
   - Creates a DynamoDB table with `LockID` as the primary key to enable state locking.

---

## Notes

- **S3 Bucket Name Uniqueness**: S3 bucket names are globally unique. Choose a name that is unlikely to be taken.
- **Region Consistency**: Ensure the region specified matches the region in your Terraform configuration.

---

## Next Steps

After creating the resources, update your `terraform.tfvars` file with the resource names:

```hcl
s3_bucket      = "dupulo-cloud-interview"
dynamodb_table = "dupulo-cloud-interview"
region         = "us-west-2"
```
