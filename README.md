# duplocloud-interview

# Deploying Terraform EKS Cluster with GitHub Actions

This guide will walk you through setting up a Terraform project that deploys an Amazon EKS (Elastic Kubernetes Service) cluster using GitHub Actions. You'll learn how to fork the repository, configure AWS credentials, set up necessary AWS resources, and customize the deployment pipeline.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Fork the Repository](#fork-the-repository)
- [Set Up AWS Credentials in GitHub Secrets](#set-up-aws-credentials-in-github-secrets)
- [Configure AWS Resources](#configure-aws-resources)
  - [Create S3 Buckets and DynamoDB Tables](#create-s3-buckets-and-dynamodb-tables)
- [Understanding the GitHub Actions Pipeline](#understanding-the-github-actions-pipeline)
- [Customizing the Deployment](#customizing-the-deployment)
  - [Add a New Cluster Name](#add-a-new-cluster-name)
  - [Modify Naming Conventions](#modify-naming-conventions)
- [Setting Up GitHub Environments for Approvals](#setting-up-github-environments-for-approvals)
- [Running the Pipeline](#running-the-pipeline)
- [Summary](#summary)
- [Troubleshooting](#troubleshooting)
- [Resources](#resources)

---

## Prerequisites

Before you begin, ensure you have the following:

- **GitHub Account**: You'll need a GitHub account to fork the repository and set up the pipeline.
- **AWS Account**: An AWS account with permissions to create EKS clusters, S3 buckets, and DynamoDB tables.
- **Basic Knowledge of AWS and Terraform**: While we'll explain each step, a basic understanding will be helpful.

---

## Fork the Repository

1. **Navigate to the Repository**:

   Go to the GitHub repository that contains the Terraform code and GitHub Actions workflow.

2. **Fork the Repository**:

   - Click the **Fork** button at the top-right corner of the repository page.
   - This will create a copy of the repository under your GitHub account.

3. **Clone the Forked Repository** (Optional):

   If you want to make local changes, clone the repository to your machine:

   ```bash
   git clone https://github.com/<your-username>/<repository-name>.git
   ```

---

## Set Up AWS Credentials in GitHub Secrets

The GitHub Actions pipeline requires AWS credentials to interact with your AWS account. We'll store these credentials securely using GitHub Secrets.

1. **Generate AWS Access Keys**:

   - Log in to your AWS Management Console.
   - Navigate to **IAM (Identity and Access Management)**.
   - Create a new user or use an existing one with programmatic access.
   - Assign the necessary permissions (e.g., AdministratorAccess for testing purposes).
   - Download the **Access Key ID** and **Secret Access Key**.

2. **Add AWS Credentials to GitHub Secrets**:

   - Go to your forked repository on GitHub.
   - Click on the **Settings** tab.
   - In the left sidebar, click on **Secrets and variables** > **Actions**.
   - Click the **New repository secret** button.

3. **Create Secrets for Each Environment**:

   The pipeline uses environment-specific AWS credentials based on the selected environment (`dev`, `qa`, `prod`). You'll need to add secrets for each environment. You can also modify it to your needs.

   - **For Dev Environment**:
     - **Name**: `AWS_ACCESS_KEY_ID_DEV`
     - **Value**: Your AWS Access Key ID
     - **Name**: `AWS_SECRET_ACCESS_KEY_DEV`
     - **Value**: Your AWS Secret Access Key

   - **For QA Environment**:
     - **Name**: `AWS_ACCESS_KEY_ID_QA`
     - **Value**: Your AWS Access Key ID (can be the same as dev for testing)
     - **Name**: `AWS_SECRET_ACCESS_KEY_QA`
     - **Value**: Your AWS Secret Access Key

   - **For Prod Environment**:
     - **Name**: `AWS_ACCESS_KEY_ID_PROD`
     - **Value**: Your AWS Access Key ID
     - **Name**: `AWS_SECRET_ACCESS_KEY_PROD`
     - **Value**: Your AWS Secret Access Key

---

## Configure AWS Resources

The Terraform backend requires an S3 bucket for state storage and a DynamoDB table for state locking. These resources must be created before running the pipeline.

### Create S3 Buckets and DynamoDB Tables

1. **Determine Naming Convention**:

   The pipeline uses the naming convention:

   ```
   <PROJECT_NAME>-<environment>
   ```

   For example, if your `PROJECT_NAME` is `my-terraform-project` and the environment is `dev`, the S3 bucket and DynamoDB table will be named:

   - S3 Bucket: `my-terraform-project-dev`
   - DynamoDB Table: `my-terraform-project-dev`


You can also run the following command to create the state resources automatically:
`./create_state_resources.sh --bucket-name dupulo-cloud-interview --table-name dupulo-cloud-interview --region us-west-2`

If you want to delete state resources you can run:
`./delete_state_resources.sh --bucket-name dupulo-cloud-interview --table-name dupulo-cloud-interview --region us-west-2`

2. **Create S3 Buckets**:

   - Log in to the AWS Management Console.
   - Navigate to **S3** service.
   - Click **Create bucket**.
   - Enter the bucket name (e.g., `my-terraform-project-dev`).
   - Choose the AWS Region.
   - Disable **Block all public access** (keep it enabled for security).
   - Click **Create bucket**.
   - **Repeat** for each environment (`qa`, `prod`).

3. **Enable Versioning on S3 Buckets** (Recommended):

   - Open your bucket.
   - Go to the **Properties** tab.
   - Click **Edit** next to **Bucket Versioning**.
   - Enable versioning and save changes.

4. **Create DynamoDB Tables**:

   - Navigate to **DynamoDB** service in AWS Management Console.
   - Click **Create table**.
   - **Table name**: Use the naming convention (e.g., `my-terraform-project-dev`).
   - **Partition key**: `LockID` (String)
   - Leave other settings as default.
   - Click **Create**.
   - **Repeat** for each environment (`qa`, `prod`).

---

## Understanding the GitHub Actions Pipeline

The pipeline is defined in the `.github/workflows` directory of your repository. Here's an overview:

- **Workflow Name**: `DEPLOY:INFRASTRUCTURE`
- **Trigger**: Manually triggered using **workflow_dispatch** with inputs.
- **Inputs**:
  - `region`: AWS Region to deploy to.
  - `environment`: Environment (`dev`, `qa`, `prod`).
  - `eks_cluster_name`: Name of the EKS cluster.
  - `instance_type`: EC2 instance type for worker nodes.
  - `number_of_nodes`, `min_number_of_nodes`, `max_number_of_nodes`: Node scaling configurations.
  - `vpc_cidr_block`: CIDR block for the VPC.
- **Environment Variables**: The inputs are exported as environment variables prefixed with `TF_VAR_`, which Terraform automatically picks up.
- **Pipeline Steps**:
  1. **Checkout Code**: Retrieves the repository code.
  2. **Configure AWS Credentials**: Sets up AWS authentication using the secrets.
  3. **Install Terraform**: Installs the required Terraform version.
  4. **Install AWS CLI**: Installs AWS CLI tools.
  5. **Replace Variables in `providers.tf`**: Adjusts the backend configuration for Terraform.
  6. **Initialize Terraform**: Runs `terraform init`.
  7. **Terraform Plan**: Runs `terraform plan`.
  8. **Terraform Apply**: Runs `terraform apply`.

---

## Customizing the Deployment

### Add a New Cluster Name

To create a new EKS cluster, you need to:

1. **Modify the Workflow File**:

   - Navigate to `.github/workflows/deploy-infrastructure.yml` in your repository.
   - Find the `eks_cluster_name` input section:

     ```yaml
     eks_cluster_name:
       description: 'EKS Cluster Name'
       required: true
       type: choice
       options:
         - 'dev-eks-cluster'
     ```

   - Add your new cluster name to the `options` list:

     ```yaml
     eks_cluster_name:
       description: 'EKS Cluster Name'
       required: true
       type: choice
       options:
         - 'dev-eks-cluster'
         - 'new-eks-cluster'
     ```

2. **Commit the Changes**:

   - Save the file and commit your changes:

     ```bash
     git add .github/workflows/deploy-infrastructure.yml
     git commit -m "Added new EKS cluster option"
     git push origin main
     ```

3. **Run the Pipeline**:

   - Go to the **Actions** tab in your GitHub repository.
   - Select the **DEPLOY:INFRASTRUCTURE** workflow.
   - Click **Run workflow**.
   - Fill out the required inputs, selecting your new cluster name.
   - Click **Run workflow**.

The pipeline will create and deploy the new EKS cluster based on your selection.

### Modify Naming Conventions

If you prefer a different naming convention for your S3 buckets and DynamoDB tables:

1. **Adjust the Pipeline Step**:

   - In the workflow file, find the **Replace variables in providers.tf** step.
   - Modify the `sed` commands to match your desired naming convention.

     ```yaml
     - name: "Replace variables in providers.tf"
       run: |
         sed -i "s|bucket *= *\"[^\"]*\"|bucket = \"your-custom-bucket-name\"|" ${{ env.TF_WORKING_DIR }}/providers.tf
         sed -i "s|dynamodb_table *= *\"[^\"]*\"|dynamodb_table = \"your-custom-table-name\"|" ${{ env.TF_WORKING_DIR }}/providers.tf
     ```

2. **Update AWS Resources**:

   - Ensure the S3 buckets and DynamoDB tables with your custom names exist in AWS.

---

## Setting Up GitHub Environments for Approvals

If you want to add manual approvals or restrictions for higher environments like `prod`, you can use GitHub Environments.

1. **Create a GitHub Environment**:

   - Go to your repository's **Settings** > **Environments**.
   - Click **New environment**.
   - Name it `prod` (or the environment you want to protect).
   - Configure any required reviewers or wait times.

2. **Modify the Workflow File**:

   - In your workflow under the `jobs` section, specify the environment:

     ```yaml
     jobs:
       deploy:
         runs-on: ubuntu-latest
         environment: ${{ inputs.environment }}
     ```

   - This tells GitHub Actions to use the environment configuration, triggering any approval steps you've set up.

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
     - **eks_cluster_name**: Select or add the EKS cluster name.
     - **instance_type**: Choose the EC2 instance type.
     - **number_of_nodes**, **min_number_of_nodes**, **max_number_of_nodes**: Set node counts.
     - **vpc_cidr_block**: Enter the VPC CIDR block.
   - Click **Run workflow**.

4. **Monitor the Pipeline**:

   - The pipeline will start running.
   - You can click on the running workflow to see real-time logs.
   - If you've set up approvals for certain environments, the pipeline will pause until approvals are granted.

---

## Summary

You've now set up a GitHub Actions pipeline that deploys a Terraform-managed EKS cluster to AWS. By following this guide, you:

- Forked the repository containing the Terraform code and GitHub Actions workflow.
- Configured AWS credentials securely using GitHub Secrets.
- Set up necessary AWS resources, including S3 buckets and DynamoDB tables.
- Learned how to customize the pipeline to add new cluster names or modify naming conventions.
- Understood how to use GitHub Environments for approvals in higher environments.

---

## Troubleshooting

- **Pipeline Fails at AWS Credentials Step**:

  - Ensure that the AWS credentials are correctly added to GitHub Secrets.
  - Verify that the secret names match the expected pattern (e.g., `AWS_ACCESS_KEY_ID_DEV`).

- **Terraform State Backend Errors**:

  - Confirm that the S3 buckets and DynamoDB tables exist with the correct names.
  - Check the `providers.tf` file to ensure the backend configuration matches your AWS resources.

- **Access Denied Errors**:

  - Make sure the AWS IAM user has the necessary permissions to create EKS clusters and related resources.

- **Approval Step Not Triggering**:

  - Verify that the GitHub Environment is correctly configured with required reviewers.
  - Ensure the `environment` key in the workflow matches the environment name.

---

### Service Checks Pipeline .github/workflows/service_checks.yaml

This GitHub Actions pipeline is designed to monitor the availability of specific service endpoints at regular intervals. If any of the endpoints return a status code other than `200 OK`, the pipeline will fail and send a notification to a designated Slack channel.

#### Key Features:
1. **Endpoint Monitoring**:
   - The pipeline checks the health of a list of service endpoints using `curl`.
   - If an endpoint is unreachable or returns a non-`200` status code, the pipeline logs an error and stops further execution.

2. **Slack Notifications**:
   - If a service check fails, a notification is sent to a specified Slack channel to alert your team.

3. **Customizable Scheduling**:
   - The pipeline runs every 5 minutes by default (`cron: '*/5 * * * *'`).
   - Users can uncomment and modify the `cron` schedule to adjust the frequency to meet their needs.

#### Configuration Steps:
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
   - Uncomment the `schedule` block if it's commented out, and modify the `cron` expression to change the frequency of checks.
   ```yaml
   schedule:
     - cron: '*/5 * * * *'  # Runs every 5 minutes
   ```

3. **Set Up Slack Notifications**:
   - Add your Slack bot token to the repository secrets as `SLACK_BOT_TOKEN`.
   - Update the `slack-channel-id` field with your Slack channel ID to specify where notifications should be sent.

#### Example Output:
- ✅ **Success**: If an endpoint is healthy, the pipeline logs a success message.
- ❌ **Error**: If an endpoint fails, the pipeline logs the error and sends a notification to the configured Slack channel.

This pipeline is a simple yet powerful way to automate service availability monitoring, ensuring your team stays informed of any potential issues in real-time.

---


## Resources

- **AWS Documentation**:
  - [Creating an IAM User in Your AWS Account](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html)
  - [Amazon S3 Getting Started Guide](https://docs.aws.amazon.com/AmazonS3/latest/gsg/GetStartedWithS3.html)
  - [Amazon DynamoDB Getting Started Guide](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/GettingStartedDynamoDB.html)
  - [Amazon EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)

- **Terraform Documentation**:
  - [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
  - [Terraform Backend Configuration](https://www.terraform.io/language/settings/backends/s3)

- **GitHub Actions Documentation**:
  - [GitHub Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
  - [GitHub Environments](https://docs.github.com/en/actions/deployment/targeting-different-environments/using-environments-for-deployment)

---

Feel free to reach out if you have any questions or need further assistance!