# duplocloud-interview

# Deploying Terraform EKS Cluster with GitHub Actions

This guide will walk you through setting up a Terraform project that deploys an Amazon EKS (Elastic Kubernetes Service) cluster using GitHub Actions. You'll learn how to fork the repository, configure AWS credentials, set up GitHub Environments with approval processes for higher environments, understand the pipeline, and run the deployment.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Fork the Repository](#fork-the-repository)
- [Set Up AWS Credentials and GitHub Environments](#set-up-aws-credentials-and-github-environments)
  - [1. Generate AWS Access Keys](#1-generate-aws-access-keys)
  - [2. Add AWS Credentials to GitHub Secrets](#2-add-aws-credentials-to-github-secrets)
  - [3. Configure GitHub Environments and Approvals](#3-configure-github-environments-and-approvals)
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

## Set Up AWS Credentials and GitHub Environments

The GitHub Actions pipeline requires AWS credentials to interact with your AWS account. The updated pipeline uses the same AWS credentials for all environments (`dev`, `qa`, `prod`), so you only need to set up a single set of AWS credentials. We'll also configure GitHub Environments to set up approval processes for higher environments.

### 1. Generate AWS Access Keys

Create an AWS IAM user with the necessary permissions to manage resources like EKS clusters, S3 buckets, and DynamoDB tables.

- **Create an IAM User**:

  - Log in to your AWS Management Console.
  - Navigate to **IAM (Identity and Access Management)**.
  - Create a new user with **Programmatic access**.
  - Assign the necessary permissions (e.g., `AdministratorAccess` for testing purposes).
  - Download the **Access Key ID** and **Secret Access Key**.

### 2. Add AWS Credentials to GitHub Secrets

We'll store the AWS credentials securely using GitHub Secrets.

1. **Go to Your Forked Repository on GitHub**:

   - Click on the **Settings** tab.
   - In the left sidebar, click on **Secrets and variables** > **Actions**.

2. **Add AWS Credentials as Secrets**:

   - Click **New repository secret**.
     - **Name**: `AWS_ACCESS_KEY_ID`
     - **Value**: Your AWS Access Key ID
   - Click **Add secret**.
   - Repeat for the Secret Access Key:
     - **Name**: `AWS_SECRET_ACCESS_KEY`
     - **Value**: Your AWS Secret Access Key

### 3. Configure GitHub Environments and Approvals

To add an approval process for higher environments like `prod`, we'll use GitHub Environments.

#### **Create GitHub Environments**

1. **Navigate to Repository Settings**:

   - Go to the **Settings** tab of your repository.

2. **Create Environments**:

   - In the left sidebar, click on **Environments**.
   - Click **New environment**.

3. **Set Up Environment for Each Stage**:

   - **Dev Environment**:
     - **Environment Name**: `dev`
     - No special configuration needed.

   - **QA Environment**:
     - **Environment Name**: `qa`
     - No special configuration needed.

   - **Prod Environment**:
     - **Environment Name**: `prod`
     - **Configure Required Reviewers**:
       - After creating the `prod` environment, click on it to configure.
       - Under **Deployment protection rules**, click **Required reviewers**.
       - Add the users or teams who are authorized to approve deployments to `prod`.
       - This ensures that any deployment to the `prod` environment requires manual approval.

#### **Relate Environments to the Pipeline**

In your GitHub Actions workflow, specify the `environment` for the job. This links the job to the GitHub Environment you've configured.

```yaml
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    # ...
```

When you run the pipeline and select the environment from the dropdown, it will use the corresponding GitHub Environment configuration, including any required approvals.

---

## Understanding the GitHub Actions Pipeline

The pipeline is defined in the `.github/workflows` directory of your repository. Here's the updated pipeline:

```yaml
name: "DEPLOY:INFRASTRUCTURE"

on:
  workflow_dispatch:
    inputs:
      region:
        description: 'Select region'
        required: true
        type: choice
        options:
          - us-east-1
          - us-west-2
          - eu-west-1
          - ap-southeast-1
          - ap-southeast-2
      environment:
        description: 'Select environment'
        required: true
        type: choice
        options:
          - dev
          - qa
          - prod
      eks_cluster_name:
        description: 'EKS Cluster Name'
        required: true
        type: choice
        options:
          - 'dev-eks-cluster'
      instance_type:
        description: 'EKS Cluster Name'
        required: true
        type: choice
        options:
          - 'm5.large'
      number_of_nodes:
        description: 'Desired number of worker nodes'
        required: true
        default: '1'
      min_number_of_nodes:
        description: 'Minimum number of worker nodes'
        required: true
        default: '1'
      max_number_of_nodes:
        description: 'Maximum number of worker nodes'
        required: true
        default: '10'
      vpc_cidr_block:
        description: 'The VPC Cidr block'
        required: true
        default: '10.0.0.0/16'
      terraform_xargs:
        description: 'additional terraform arguments. ex. -lock=false'
        required: true
        default: ''
      terraform_application:
        description: 'Which infrastructure piece of terraform do you want to deploy.'
        required: true
        type: choice
        options:
          - eks
jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    env:
      TF_VAR_environment: '${{ inputs.environment }}'
      TF_VAR_region: '${{ inputs.region }}'
      TF_VAR_vpc_cidr_block: '${{ inputs.vpc_cidr_block }}'
      TF_VAR_eks_cluster_name: '${{ inputs.eks_cluster_name }}'
      TF_VAR_instance_type: '${{ inputs.instance_type }}'
      TF_VAR_number_of_nodes: '${{ inputs.number_of_nodes }}'
      TF_VAR_max_number_of_nodes: '${{ inputs.max_number_of_nodes }}'
      TF_VAR_min_number_of_nodes: '${{ inputs.min_number_of_nodes }}'
      TF_WORKING_DIR: "terraform/${{ inputs.terraform_application }}"
      PROJECT_NAME: "dupulo-cloud-interview"

    steps:
      - name: "Checkout code"
        uses: actions/checkout@v3

      - name: "Configure AWS credentials for ${{ env.TF_VAR_environment }} environment"
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.TF_VAR_region }}

      - name: "Install Terraform"
        uses: hashicorp/setup-terraform@v2
        with:
          terraform_version: 1.3.3

      - name: "Install AWS CLI"
        run: |
          sudo apt-get update
          sudo apt-get install -y awscli

      - name: "Check and Create S3 Bucket and DynamoDB Table"
        run: |
          BUCKET_NAME="${{ env.PROJECT_NAME }}-${{ env.TF_VAR_environment }}"
          TABLE_NAME="${{ env.PROJECT_NAME }}-${{ env.TF_VAR_environment }}"
          REGION="${{ env.TF_VAR_region }}"

          echo "Checking if S3 bucket $BUCKET_NAME exists and DynamoDB table $TABLE_NAME exists..."
          if ! aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null || ! aws dynamodb describe-table --table-name "$TABLE_NAME" --region "$REGION" 2>/dev/null; then
              echo "Either the S3 bucket $BUCKET_NAME or DynamoDB table $TABLE_NAME does not exist. Creating resources..."
              ./base_config_scripts/create_state_resources.sh --bucket-name "$BUCKET_NAME" --table-name "$TABLE_NAME" --region "$REGION"
          else
              echo "Both S3 bucket $BUCKET_NAME and DynamoDB table $TABLE_NAME exist."
          fi

      - name: "Replace variables in providers.tf"
        run: |
          sed -i "s|bucket *= *\"[^\"]*\"|bucket = \"${{ env.PROJECT_NAME }}-${{ env.TF_VAR_environment }}\"|" ${{ env.TF_WORKING_DIR }}/providers.tf
          sed -i "s|key *= *\"[^\"]*\"|key = \"${{ env.TF_VAR_environment }}/terraform.tfstate\"|" ${{ env.TF_WORKING_DIR }}/providers.tf
          sed -i "s|region *= *\"[^\"]*\"|region = \"${{ env.TF_VAR_region }}\"|" ${{ env.TF_WORKING_DIR }}/providers.tf
          sed -i "s|dynamodb_table *= *\"[^\"]*\"|dynamodb_table = \"${{ env.PROJECT_NAME }}-${{ env.TF_VAR_environment }}\"|" ${{ env.TF_WORKING_DIR }}/providers.tf
          cat ${{ env.TF_WORKING_DIR }}/providers.tf

      - name: "Initialize Terraform"
        working-directory: ${{ env.TF_WORKING_DIR }}
        run: terraform init

      - name: "Terraform Plan"
        working-directory: ${{ env.TF_WORKING_DIR }}
        run: terraform plan -out=tfplan

      - name: "Terraform Apply"
        working-directory: ${{ env.TF_WORKING_DIR }}
        run: terraform apply -auto-approve tfplan ${{ inputs.terraform_xargs }}
```

### Key Points:

- **AWS Credentials**: The pipeline uses the same AWS credentials for all environments, stored in `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.
- **GitHub Environments with Approvals**: Deployments to higher environments like `prod` can be configured to require manual approval from designated reviewers.
- **Automatic Resource Creation**: The pipeline automatically checks for and creates the S3 bucket and DynamoDB table needed for the Terraform backend.
- **Environment Variable Usage**: The `environment` input in the workflow dispatch corresponds to the GitHub Environment configuration for approvals.

---

## Running the Pipeline

1. **Navigate to GitHub Actions**:

   - Go to the **Actions** tab in your repository.

2. **Select the Workflow**:

   - Choose the **DEPLOY:INFRASTRUCTURE** workflow.

3. **Run the Workflow**:

   - Click **Run workflow**.
   - Fill in the required inputs:
     - **region**: Select the AWS region (e.g., `us-west-2`).
     - **environment**: Choose the environment (`dev`, `qa`, `prod`).
     - **eks_cluster_name**: Select or enter the EKS cluster name (e.g., `dev-eks-cluster`).
     - **instance_type**: Choose the EC2 instance type (e.g., `m5.large`).
     - **number_of_nodes**, **min_number_of_nodes**, **max_number_of_nodes**: Set node counts.
     - **vpc_cidr_block**: Enter the VPC CIDR block (e.g., `10.0.0.0/16`).
     - **terraform_application**: Choose the Terraform application to deploy (e.g., `eks`).
     - **terraform_xargs**: Any additional Terraform arguments (optional).
   - Click **Run workflow**.

4. **Monitor the Pipeline**:

   - The pipeline will start running.
   - Click on the running workflow to see real-time logs.
   - If deploying to `prod`, the pipeline will pause and await approval from the designated reviewers.
   - Approvers will receive a notification to review and approve the deployment.
   - Once approved, the pipeline will proceed with the deployment.

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

3. **Set Terraform Variables**:

   **Option 1: Using Environment Variables**

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

5. **Review the Plan**:

   Examine the output to ensure that the resources to be created match your expectations.

6. **Apply the Plan**:

   ```bash
   terraform apply tfplan
   ```

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
- Configure AWS credentials using GitHub Secrets without environment-specific namespacing.
- Set up GitHub Environments with approval processes for higher environments like `prod`.
- Run the pipeline with the environment dropdown relating to GitHub Environments and approvals.
- Manually deploy the infrastructure using Terraform commands.

---

## Troubleshooting

- **AWS Credentials Errors**:

  - Ensure that your AWS credentials are correctly added to GitHub Secrets as `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.
  - Verify that the AWS credentials have the necessary permissions for all environments.

- **Approval Not Triggered for Prod Deployment**:

  - Check that the `prod` GitHub Environment is correctly configured with required reviewers.
  - Ensure that the `environment` input in the workflow matches the GitHub Environment name.

- **Secrets Not Accessible in Pipeline**:

  - Confirm that the secrets are correctly named and that the syntax for accessing them in the workflow is correct.
  - Remember that secret names are case-sensitive.

- **Terraform State Backend Errors**:

  - The pipeline automatically creates the S3 bucket and DynamoDB table if they don't exist.
  - If errors occur, check the logs for the "Check and Create S3 Bucket and DynamoDB Table" step for details.

- **Permission Denied Errors**:

  - Ensure the AWS IAM user has the necessary permissions for the actions you're performing.
  - Check AWS policies attached to your IAM user.

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
  - [Encrypted Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
  - [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)
  - [Approval Workflows](https://docs.github.com/en/actions/managing-workflow-runs/requiring-approval-for-workflows)

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

---

## Service Checks Pipeline `.github/workflows/service_checks.yaml`

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
