# duplocloud-interview

# Deploying Terraform EKS Cluster with GitHub Actions

This guide will walk you through setting up a Terraform project that deploys an Amazon EKS (Elastic Kubernetes Service) cluster using GitHub Actions. You'll learn how to fork the repository, configure AWS credentials with environment-based secrets, set up GitHub Environments with approval processes for higher environments, understand the pipeline, and run the deployment.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Fork the Repository](#fork-the-repository)
- [Set Up AWS Credentials and GitHub Environments](#set-up-aws-credentials-and-github-environments)
  - [1. Generate AWS Access Keys for Each Environment](#1-generate-aws-access-keys-for-each-environment)
  - [2. Add AWS Credentials to GitHub Secrets](#2-add-aws-credentials-to-github-secrets)
  - [3. Configure GitHub Environments and Approvals](#3-configure-github-environments-and-approvals)
  - [4. Update the Pipeline to Use Environment-Based Secrets](#4-update-the-pipeline-to-use-environment-based-secrets)
- [Understanding the GitHub Actions Pipeline](#understanding-the-github-actions-pipeline)
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

The GitHub Actions pipeline requires AWS credentials to interact with your AWS account. To enhance security and control, especially when deploying to different environments (`dev`, `qa`, `prod`), we'll store environment-specific AWS credentials securely using GitHub Secrets and configure GitHub Environments for approval workflows.

### 1. Generate AWS Access Keys for Each Environment

For each environment (`dev`, `qa`, `prod`), create separate AWS IAM users or roles with appropriate permissions.

#### **Create AWS IAM Users/Roles**

- **For Dev Environment**:
  - Create an IAM user or role with permissions limited to development resources.
  - Generate an **Access Key ID** and **Secret Access Key** for this user.

- **For QA Environment**:
  - Create an IAM user or role with permissions for QA resources.
  - Generate an **Access Key ID** and **Secret Access Key** for this user.

- **For Prod Environment**:
  - Create an IAM user or role with permissions for production resources.
  - For enhanced security, consider using MFA and strict policies.
  - Generate an **Access Key ID** and **Secret Access Key** for this user.

### 2. Add AWS Credentials to GitHub Secrets

We will store the AWS credentials for each environment in GitHub Secrets, namespaced by environment.

1. **Go to Your Forked Repository on GitHub**:

   - Click on the **Settings** tab.
   - In the left sidebar, click on **Secrets and variables** > **Actions**.

2. **Add Secrets for Each Environment**:

   - **For Dev Environment**:
     - Click **New repository secret**.
       - **Name**: `AWS_ACCESS_KEY_ID_DEV`
       - **Value**: AWS Access Key ID for the Dev environment.
     - Click **Add secret**.
     - Repeat for the Secret Access Key:
       - **Name**: `AWS_SECRET_ACCESS_KEY_DEV`
       - **Value**: AWS Secret Access Key for the Dev environment.

   - **For QA Environment**:
     - Add secrets named `AWS_ACCESS_KEY_ID_QA` and `AWS_SECRET_ACCESS_KEY_QA` with the corresponding values.

   - **For Prod Environment**:
     - Add secrets named `AWS_ACCESS_KEY_ID_PROD` and `AWS_SECRET_ACCESS_KEY_PROD` with the corresponding values.

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

### 4. Update the Pipeline to Use Environment-Based Secrets

Modify your GitHub Actions workflow to use the environment-specific AWS credentials based on the selected environment.

In your workflow file (e.g., `.github/workflows/deploy-infrastructure.yml`), update the AWS credentials step:

```yaml
- name: "Configure AWS credentials for ${{ env.TF_VAR_environment }} environment"
  uses: aws-actions/configure-aws-credentials@v1
  with:
    aws-access-key-id: ${{ secrets['AWS_ACCESS_KEY_ID_' + env.TF_VAR_environment | upper ] }}
    aws-secret-access-key: ${{ secrets['AWS_SECRET_ACCESS_KEY_' + env.TF_VAR_environment | upper ] }}
    aws-region: ${{ env.TF_VAR_region }}
```

**Explanation**:

- We're dynamically accessing the secrets based on the `environment` variable.
- The `env.TF_VAR_environment | upper` converts the environment name to uppercase to match the secret naming convention.

---

By setting up environment-based secrets and GitHub Environments with approval processes, you enhance the security and control of your deployment pipeline. This setup ensures that deployments to sensitive environments like `prod` require explicit approval from authorized personnel.

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
  2. **Configure AWS Credentials**: Sets up AWS authentication using the environment-specific secrets.
  3. **Install Terraform**: Installs the required Terraform version.
  4. **Install AWS CLI**: Installs AWS CLI tools.
  5. **Check and Create S3 Bucket and DynamoDB Table**: Checks if the necessary S3 bucket and DynamoDB table exist; if not, it creates them using scripts.
  6. **Replace Variables in `providers.tf`**: Adjusts the backend configuration for Terraform.
  7. **Initialize Terraform**: Runs `terraform init`.
  8. **Terraform Plan**: Runs `terraform plan`.
  9. **Terraform Apply**: Runs `terraform apply`.

### Key Points:

- **Environment-Based AWS Credentials**: The pipeline uses environment-specific AWS credentials stored in secrets like `AWS_ACCESS_KEY_ID_DEV`, `AWS_ACCESS_KEY_ID_QA`, etc.
- **GitHub Environments with Approvals**: Deployments to higher environments like `prod` require manual approval from designated reviewers.
- **Automatic Resource Creation**: The pipeline automatically checks for and creates the S3 bucket and DynamoDB table needed for the Terraform backend.
- **Relating Environments to the Pipeline**: The `environment` input in the workflow dispatch corresponds to both the AWS credentials used and the GitHub Environment configuration.

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
   - If deploying to `prod`, the pipeline will pause and await approval from the designated reviewers.
   - Approvers will receive a notification to review and approve the deployment.
   - Once approved, the pipeline will proceed with the deployment.

---

## Summary

You've now learned how to:

- Use GitHub Actions to automate the deployment of an EKS cluster with Terraform.
- Set up environment-based AWS credentials and GitHub Environments with approval processes.
- Modify the pipeline to use environment-specific secrets and approvals.
- Run the pipeline with the environment dropdown relating to both AWS credentials and GitHub Environments.

---

## Troubleshooting

- **AWS Credentials Errors**:

  - Ensure that your AWS credentials are correctly added to GitHub Secrets with the correct naming convention (e.g., `AWS_ACCESS_KEY_ID_DEV`).
  - Verify that the AWS credentials have the necessary permissions for their respective environments.

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

  - Ensure the AWS IAM users have the necessary permissions for the actions they're performing.
  - Check AWS policies attached to your IAM users.

---

## Resources

- **AWS Documentation**:
  - [Creating an IAM User in Your AWS Account](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_users_create.html)
  - [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
  - [Amazon EKS User Guide](https://docs.aws.amazon.com/eks/latest/userguide/what-is-eks.html)

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

## Updated Workflow File (`.github/workflows/deploy-infrastructure.yml`)

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
        default: 'dev-eks-cluster'
      instance_type:
        description: 'Instance Type'
        required: true
        default: 'm5.large'
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
        description: 'The VPC CIDR block'
        required: true
        default: '10.0.0.0/16'
      terraform_xargs:
        description: 'Additional Terraform arguments. ex. -lock=false'
        required: false
        default: ''
      terraform_application:
        description: 'Which infrastructure piece of Terraform do you want to deploy.'
        required: true
        default: 'eks'

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
          aws-access-key-id: ${{ secrets['AWS_ACCESS_KEY_ID_' + env.TF_VAR_environment | upper ] }}
          aws-secret-access-key: ${{ secrets['AWS_SECRET_ACCESS_KEY_' + env.TF_VAR_environment | upper ] }}
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
