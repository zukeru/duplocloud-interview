# duplocloud-interview

# Deploying Terraform EKS Cluster with GitHub Actions and Manual Deployment

This guide will walk you through setting up a Terraform project that deploys an Amazon EKS (Elastic Kubernetes Service) cluster using GitHub Actions and how to deploy it manually using Terraform commands. You'll learn how to fork the repository, configure AWS credentials, understand the pipeline, and run the deployment both automatically and manually.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Fork the Repository](#fork-the-repository)
- [Set Up AWS Credentials in GitHub Secrets](#set-up-aws-credentials-in-github-secrets)
- [Understanding the GitHub Actions Pipeline](#understanding-the-github-actions-pipeline)
- [Running the Pipeline](#running-the-pipeline)
- [Manual Deployment with Terraform](#manual-deployment-with-terraform)
  - [Create State Resources](#create-state-resources)
  - [Modify the `providers.tf` File](#modify-the-providerstf-file)
  - [Run Terraform Commands Manually](#run-terraform-commands-manually)
- [Summary](#summary)
- [Troubleshooting](#troubleshooting)
- [Resources](#resources)

---

## Prerequisites

Before you begin, ensure you have the following:

- **GitHub Account**: You'll need a GitHub account to fork the repository and set up the pipeline.
- **AWS Account**: An AWS account with permissions to create EKS clusters, S3 buckets, and DynamoDB tables.
- **Basic Knowledge of AWS and Terraform**: While we'll explain each step, a basic understanding will be helpful.
- **Terraform Installed Locally**: For manual deployment, ensure you have Terraform installed on your machine.
- **AWS CLI Installed Locally**: Install the AWS CLI to interact with AWS services from your terminal.

---

## Fork the Repository

1. **Navigate to the Repository**:

   Go to the GitHub repository that contains the Terraform code and GitHub Actions workflow.

2. **Fork the Repository**:

   - Click the **Fork** button at the top-right corner of the repository page.
   - This will create a copy of the repository under your GitHub account.

3. **Clone the Forked Repository**:

   Clone the repository to your local machine:

   ```bash
   git clone https://github.com/<your-username>/<repository-name>.git
   ```

---

## Set Up AWS Credentials in GitHub Secrets

The GitHub Actions pipeline requires AWS credentials to interact with your AWS account. We'll store these credentials securely using GitHub Secrets.

1. **Generate AWS Access Keys**:

   - Log in to your AWS Management Console.
   - Navigate to **IAM (Identity and Access Management)**.
   - Create a new user with programmatic access.
   - Assign the necessary permissions (e.g., `AdministratorAccess` for testing purposes).
   - Download the **Access Key ID** and **Secret Access Key**.

2. **Add AWS Credentials to GitHub Secrets**:

   - Go to your forked repository on GitHub.
   - Click on the **Settings** tab.
   - In the left sidebar, click on **Secrets and variables** > **Actions**.
   - Click the **New repository secret** button.

3. **Create AWS Secrets**:

   Add the following secrets:

   - **AWS Access Key ID**:
     - **Name**: `AWS_ACCESS_KEY_ID`
     - **Value**: Your AWS Access Key ID
   - **AWS Secret Access Key**:
     - **Name**: `AWS_SECRET_ACCESS_KEY`
     - **Value**: Your AWS Secret Access Key

---

## Understanding the GitHub Actions Pipeline

The pipeline is defined in the `.github/workflows` directory of your repository. Here's an overview:

- **Workflow Name**: `DEPLOY:INFRASTRUCTURE`
- **Trigger**: Manually triggered using `workflow_dispatch` with inputs.
- **Inputs**:
  - `region`: AWS Region to deploy to.
  - `environment`: Environment (`dev`, `qa`, `prod`).
  - `eks_cluster_name`: Name of the EKS cluster.
  - `instance_type`: EC2 instance type for worker nodes.
  - `number_of_nodes`, `min_number_of_nodes`, `max_number_of_nodes`: Node scaling configurations.
  - `vpc_cidr_block`: CIDR block for the VPC.
  - `terraform_application`: The specific Terraform application to deploy (e.g., `eks`).
  - `terraform_xargs`: Additional Terraform arguments.
- **Environment Variables**: The inputs are exported as environment variables prefixed with `TF_VAR_`, which Terraform automatically picks up.
- **Pipeline Steps**:
  1. **Checkout Code**: Retrieves the repository code.
  2. **Configure AWS Credentials**: Sets up AWS authentication using the secrets.
  3. **Install Terraform**: Installs the required Terraform version.
  4. **Install AWS CLI**: Installs AWS CLI tools.
  5. **Check and Create S3 Bucket and DynamoDB Table**: Checks if the necessary S3 bucket and DynamoDB table exist; if not, it creates them using scripts.
  6. **Replace Variables in `providers.tf`**: Adjusts the backend configuration for Terraform.
  7. **Initialize Terraform**: Runs `terraform init`.
  8. **Terraform Plan**: Runs `terraform plan`.
  9. **Terraform Apply**: Runs `terraform apply`.

### Key Points:

- **AWS Credentials**: The pipeline uses the same AWS credentials for all environments, stored in `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.
- **Automatic Resource Creation**: The pipeline automatically checks for and creates the S3 bucket and DynamoDB table needed for the Terraform backend.
- **Simplified Secrets**: No need to create environment-specific AWS secrets; a single set suffices.

---

## Running the Pipeline

1. **Navigate to GitHub Actions**:

   - Go to the **Actions** tab in your repository.

2. **Select the Workflow**:

   - Choose the **DEPLOY:INFRASTRUCTURE** workflow.

3. **Run the Workflow**:

   - Click **Run workflow**.
   - Fill in the required inputs:
     - **region**: Select the AWS region.
     - **environment**: Choose the environment (`dev`, `qa`, `prod`).
     - **eks_cluster_name**: Enter the EKS cluster name.
     - **instance_type**: Choose the EC2 instance type (e.g., `m5.large`).
     - **number_of_nodes**, **min_number_of_nodes**, **max_number_of_nodes**: Set node counts.
     - **vpc_cidr_block**: Enter the VPC CIDR block (e.g., `10.0.0.0/16`).
     - **terraform_application**: Choose the Terraform application to deploy (e.g., `eks`).
     - **terraform_xargs**: Any additional Terraform arguments (optional).
   - Click **Run workflow**.

4. **Monitor the Pipeline**:

   - The pipeline will start running.
   - Click on the running workflow to see real-time logs.
   - The pipeline will:
     - Automatically check and create the S3 bucket and DynamoDB table if they don't exist.
     - Replace variables in `providers.tf` with the inputs provided.
     - Initialize Terraform, plan, and apply the configuration.

---

## Manual Deployment with Terraform

If you prefer to deploy the infrastructure manually using Terraform commands, follow these steps.

### Create State Resources

The Terraform backend requires an S3 bucket for state storage and a DynamoDB table for state locking. These resources must be created before running Terraform.

#### Using the Provided Script

The repository includes scripts to create and delete the necessary AWS resources.

1. **Navigate to the `base_config_scripts` Directory**:

   ```bash
   cd base_config_scripts
   ```

2. **Run the `create_state_resources.sh` Script**:

   The script accepts the following parameters:

   - `--bucket-name`: Name of the S3 bucket to create.
   - `--table-name`: Name of the DynamoDB table to create.
   - `--region`: AWS region where the resources will be created.

   **Example**:

   ```bash
   ./create_state_resources.sh --bucket-name dupulo-cloud-interview-dev --table-name dupulo-cloud-interview-dev --region us-west-2
   ```

   This command will create:

   - An S3 bucket named `dupulo-cloud-interview-dev`.
   - A DynamoDB table named `dupulo-cloud-interview-dev`.
   - Both in the `us-west-2` region.

3. **Verify the Resources**:

   - Log in to the AWS Management Console.
   - Navigate to the **S3** service and confirm that the bucket exists.
   - Navigate to the **DynamoDB** service and confirm that the table exists.

### Modify the `providers.tf` File

Before running Terraform commands, you need to configure the backend in the `providers.tf` file to use the S3 bucket and DynamoDB table you just created.

1. **Open the `providers.tf` File**:

   Located in the Terraform application directory, e.g., `terraform/eks/providers.tf`.

2. **Update the Backend Configuration**:

   Replace the existing content with the following, making sure to replace placeholders with your actual values:

   ```hcl
   terraform {
     required_version = ">= 1.3.3"
     backend "s3" {
       bucket         = "dupulo-cloud-interview-dev"
       key            = "dev/terraform.tfstate"
       region         = "us-west-2"
       dynamodb_table = "dupulo-cloud-interview-dev"
       encrypt        = true
     }
   }

   provider "aws" {
     region = var.region
   }

   provider "kubernetes" {
     host                   = module.eks.cluster_endpoint
     cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
     token                  = data.aws_eks_cluster_auth.cluster.token
   }
   ```

   - **bucket**: Name of your S3 bucket.
   - **key**: Path to the Terraform state file within the bucket.
   - **region**: AWS region.
   - **dynamodb_table**: Name of your DynamoDB table.

3. **Save the Changes**.

### Run Terraform Commands Manually

Now that the backend is configured, you can proceed to run Terraform commands.

1. **Navigate to the Terraform Directory**:

   ```bash
   cd ../terraform/eks
   ```

2. **Initialize Terraform**:

   ```bash
   terraform init
   ```

   - This command initializes the backend and downloads the necessary provider plugins.

3. **Set Terraform Variables**:

   You can set variables via command-line options, environment variables, or a `terraform.tfvars` file.

   **Option 1: Using Environment Variables**

   Set variables prefixed with `TF_VAR_`.

   ```bash
   export TF_VAR_region="us-west-2"
   export TF_VAR_environment="dev"
   export TF_VAR_vpc_cidr_block="10.0.0.0/16"
   export TF_VAR_eks_cluster_name="dev-eks-cluster"
   export TF_VAR_instance_type="m5.large"
   export TF_VAR_number_of_nodes="1"
   export TF_VAR_min_number_of_nodes="1"
   export TF_VAR_max_number_of_nodes="10"
   ```

   **Option 2: Using a `terraform.tfvars` File**

   Create a file named `terraform.tfvars` with the following content:

   ```hcl
   region            = "us-west-2"
   environment       = "dev"
   vpc_cidr_block    = "10.0.0.0/16"
   eks_cluster_name  = "dev-eks-cluster"
   instance_type     = "m5.large"
   number_of_nodes   = 1
   min_number_of_nodes = 1
   max_number_of_nodes = 10
   ```

4. **Run Terraform Plan**:

   ```bash
   terraform plan -out=tfplan
   ```

   - This command creates an execution plan and saves it to `tfplan`.

5. **Review the Plan**:

   - Examine the output to ensure that the resources to be created match your expectations.

6. **Apply the Plan**:

   ```bash
   terraform apply tfplan
   ```

   - This command applies the changes required to reach the desired state of the configuration.

7. **Commit Changes (Optional)**:

   If you made changes to the Terraform configuration files, commit them to your repository:

   ```bash
   git add .
   git commit -m "Deployed EKS cluster manually"
   git push origin main
   ```

---

## Summary

You've now learned how to:

- Use GitHub Actions to automate the deployment of an EKS cluster with Terraform.
- Manually deploy the infrastructure using Terraform commands.
- Create necessary AWS resources for Terraform state management using provided scripts.
- Modify the `providers.tf` file to configure the Terraform backend.
- Run Terraform commands to initialize, plan, and apply your infrastructure changes.

---

## Troubleshooting

- **AWS Credentials Errors**:

  - Ensure that your AWS credentials are correctly configured in your local environment (`~/.aws/credentials`) or set as environment variables.
  - Verify that the AWS credentials have the necessary permissions.

- **S3 Bucket or DynamoDB Table Already Exists**:

  - If you receive errors about resources already existing, check if the bucket or table was previously created.
  - Adjust the names to avoid conflicts or proceed if it's intentional.

- **Terraform Initialization Errors**:

  - Ensure that the `providers.tf` file is correctly configured.
  - Verify network connectivity to AWS services.

- **Permission Denied Errors**:

  - Make sure your IAM user or role has the necessary permissions for the actions you're performing.
  - Check AWS policies attached to your IAM user or role.

- **State Locking Errors**:

  - If you encounter errors about the state being locked, ensure that no other Terraform process is running.
  - You can manually unlock the state via DynamoDB if necessary.

---

## Resources

- **AWS Documentation**:
  - [Creating an IAM User in Your AWS Account](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html)
  - [Amazon EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)
  - [Amazon S3 Getting Started Guide](https://docs.aws.amazon.com/AmazonS3/latest/gsg/GetStartedWithS3.html)
  - [Amazon DynamoDB Getting Started Guide](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GettingStartedDynamoDB.html)

- **Terraform Documentation**:
  - [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
  - [Terraform Backend Configuration](https://www.terraform.io/language/settings/backends/s3)
  - [Terraform CLI Commands](https://www.terraform.io/cli/commands)

- **GitHub Actions Documentation**:
  - [GitHub Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
  - [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)

---

Feel free to customize and extend this guide based on your specific requirements and organizational standards. If you have any questions or need further assistance, don't hesitate to reach out!

---

# Appendix

## `providers.tf` File Example

Here is an example of how your `providers.tf` file should look after modification:

```hcl
terraform {
  required_version = ">= 1.3.3"
  backend "s3" {
    bucket         = "dupulo-cloud-interview-dev"
    key            = "dev/terraform.tfstate"
    region         = "us-west-2"
    dynamodb_table = "dupulo-cloud-interview-dev"
    encrypt        = true
  }
}

provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token
}
```

---

## Scripts for State Resources Management

### Create State Resources Script (`create_state_resources.sh`)

```bash
#!/bin/bash

set -e

usage() {
  echo "Usage: $0 --bucket-name <bucket_name> --table-name <table_name> --region <region>"
  exit 1
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --bucket-name) BUCKET_NAME="$2"; shift ;;
    --table-name) TABLE_NAME="$2"; shift ;;
    --region) REGION="$2"; shift ;;
    *) usage ;;
  esac
  shift
done

if [[ -z "$BUCKET_NAME" || -z "$TABLE_NAME" || -z "$REGION" ]]; then
  usage
fi

echo "Creating S3 bucket: $BUCKET_NAME"
aws s3api create-bucket --bucket "$BUCKET_NAME" --region "$REGION" --create-bucket-configuration LocationConstraint="$REGION"

echo "Enabling versioning on S3 bucket: $BUCKET_NAME"
aws s3api put-bucket-versioning --bucket "$BUCKET_NAME" --versioning-configuration Status=Enabled

echo "Creating DynamoDB table: $TABLE_NAME"
aws dynamodb create-table \
  --table-name "$TABLE_NAME" \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region "$REGION"

echo "State resources created successfully."
```

### Delete State Resources Script (`delete_state_resources.sh`)

```bash
#!/bin/bash

set -e

usage() {
  echo "Usage: $0 --bucket-name <bucket_name> --table-name <table_name> --region <region>"
  exit 1
}

while [[ "$#" -gt 0 ]]; do
  case $1 in
    --bucket-name) BUCKET_NAME="$2"; shift ;;
    --table-name) TABLE_NAME="$2"; shift ;;
    --region) REGION="$2"; shift ;;
    *) usage ;;
  esac
  shift
done

if [[ -z "$BUCKET_NAME" || -z "$TABLE_NAME" || -z "$REGION" ]]; then
  usage
fi

echo "Deleting all objects from S3 bucket: $BUCKET_NAME"
aws s3api delete-objects --bucket "$BUCKET_NAME" --delete "$(aws s3api list-object-versions --bucket "$BUCKET_NAME" --output=json --query='{Objects: Versions[].{Key:Key,VersionId:VersionId}}')"

echo "Deleting S3 bucket: $BUCKET_NAME"
aws s3api delete-bucket --bucket "$BUCKET_NAME" --region "$REGION"

echo "Deleting DynamoDB table: $TABLE_NAME"
aws dynamodb delete-table --table-name "$TABLE_NAME" --region "$REGION"

echo "State resources deleted successfully."
```

---

# Service Checks Pipeline `.github/workflows/service_checks.yaml`

This GitHub Actions pipeline is designed to monitor the availability of specific service endpoints. If any of the endpoints return a status code other than `200 OK`, the pipeline will fail and send a notification to a designated Slack channel.

### Key Features:

1. **Endpoint Monitoring**:

   - The pipeline checks the health of a list of service endpoints using `curl`.
   - If an endpoint is unreachable or returns a non-`200` status code, the pipeline logs an error and stops further execution.

2. **Slack Notifications**:

   - If a service check fails, a notification is sent to a specified Slack channel to alert your team.

3. **Customizable Scheduling**:

   - The pipeline can be configured to run on a schedule using the `cron` syntax.

### Configuration Steps:

1. **Modify the Endpoint List**:

   - Update the `ENDPOINTS` array in the pipeline to include the service URLs you want to monitor.

     ```bash
     ENDPOINTS=(
       "https://example.com/api1"
       "https://example.com/api2"
       "https://example.com/api3"
     )
     ```

2. **Adjust the Schedule**:

   - Uncomment the `schedule` block and modify the `cron` expression to change the frequency of checks.

     ```yaml
     schedule:
       - cron: '*/5 * * * *'  # Runs every 5 minutes
     ```

3. **Set Up Slack Notifications**:

   - Add your Slack bot token to the repository secrets as `SLACK_BOT_TOKEN`.
   - Update the `slack-channel-id` field with your Slack channel ID to specify where notifications should be sent.

### Example Output:

- ✅ **Success**: If an endpoint is healthy, the pipeline logs a success message.
- ❌ **Error**: If an endpoint fails, the pipeline logs the error and sends a notification to the configured Slack channel.

This pipeline is a simple yet powerful way to automate service availability monitoring, ensuring your team stays informed of any potential issues in real-time.

---

