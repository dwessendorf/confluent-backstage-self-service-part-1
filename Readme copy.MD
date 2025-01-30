# Setting Up Backstage for Automated Confluent Cloud Provisioning: A Step-by-Step Guide (Part 1)

Welcome to the first part of our comprehensive guide on setting up Backstage for managing your Confluent Cloud resources! In this installment, we'll walk you through the initial setup and configuration required to create a functional Backstage application capable of provisioning a new Confluent Cloud environment and cluster. By the end of this post, you'll have a fully automated system integrated with GitHub and Terraform, streamlining your infrastructure management processes.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [1. Backstage Installation](#1-backstage-installation)
3. [2. GitHub Integration](#2-github-integration)
4. [3. Terraform Project Setup](#3-terraform-project-setup)
5. [4. Initial Confluent Cloud Integration](#4-initial-confluent-cloud-integration)
6. [5. Validating the Setup](#5-validating-the-setup)
7. [Conclusion](#conclusion)

---

## Prerequisites

Before diving into the setup, ensure you have the following prerequisites in place:

- **Node.js and npm**: Backstage requires Node.js (version 14.15.0 or later) and npm.
- **GitHub Account**: For repository hosting and pipeline automation.
- **Terraform Installed**: Version 1.0 or later.
- **Confluent Cloud Account**: To provision and manage cloud resources.
- **Basic Knowledge of JavaScript/TypeScript, Git, and Terraform**: Familiarity with these technologies will be beneficial.

---

## 1. Backstage Installation

Backstage is an open-source platform for building developer portals. We'll start by bootstrapping a new Backstage instance using the official Backstage CLI.

### Step 1.1: Install the Backstage CLI

First, install the Backstage CLI globally using npm:

```bash
npm install -g @backstage/cli
```

### Step 1.2: Create a New Backstage App

Navigate to your desired directory and create a new Backstage app:

```bash
mkdir my-backstage-app
cd my-backstage-app
backstage create-app
```

You'll be prompted to enter details about your app:

- **App name**: e.g., `confluent-backstage`
- **Backend language**: JavaScript or TypeScript (TypeScript is recommended)
- **Package manager**: npm or yarn

Follow the prompts to complete the setup. Once done, navigate into your new app directory:

```bash
cd confluent-backstage
```

### Step 1.3: Run the Backstage App

Start the Backstage development server:

```bash
yarn dev
```

By default, Backstage runs on [http://localhost:3000](http://localhost:3000). Open this URL in your browser to verify that your Backstage instance is up and running.

---

## 2. GitHub Integration

Integrating GitHub with Backstage allows for seamless pipeline automation and repository management.

### Step 2.1: Create a GitHub OAuth App

1. **Navigate to GitHub Settings**:
   - Go to your GitHub account settings.
   - Select **Developer settings** > **OAuth Apps** > **New OAuth App**.

2. **Register a New OAuth Application**:
   - **Application name**: e.g., `Backstage Integration`
   - **Homepage URL**: `http://localhost:3000` (during development)
   - **Authorization callback URL**: `http://localhost:3000/api/auth/github/handler/frame`

3. **Save the OAuth App** and note down the **Client ID** and **Client Secret**.

### Step 2.2: Configure Backstage with GitHub Credentials

Create a `.env` file in the root of your Backstage project (if not already present) and add your GitHub OAuth credentials:

```dotenv
GITHUB_CLIENT_ID=your_github_client_id
GITHUB_CLIENT_SECRET=your_github_client_secret
```

### Step 2.3: Update Backstage Configuration

Modify `app-config.yaml` to include GitHub authentication:

```yaml
auth:
  providers:
    github:
      development:
        clientId: ${GITHUB_CLIENT_ID}
        clientSecret: ${GITHUB_CLIENT_SECRET}
```

### Step 2.4: Set Up GitHub Repository for Backstage

1. **Create a New Repository**:
   - Name it appropriately, e.g., `backstage-automation`.

2. **Clone the Repository**:

```bash
git clone https://github.com/your-org/backstage-automation.git
cd backstage-automation
```

3. **Link Repository to Backstage**:

   In Backstage, navigate to **Settings** > **Integrations** > **GitHub** and add your repository. This will allow Backstage to interact with your GitHub repositories for pipeline automation.

---

## 3. Terraform Project Setup

Terraform will manage your Confluent Cloud resources. We'll set up a basic folder structure to organize our Terraform configuration.

### Step 3.1: Install Terraform

If you haven't already, install Terraform from the [official website](https://www.terraform.io/downloads.html).

### Step 3.2: Initialize Terraform Project

Create a new directory for your Terraform configurations:

```bash
mkdir terraform
cd terraform
```

Initialize a new Terraform project:

```bash
terraform init
```

### Step 3.3: Define Folder Structure

Organize your Terraform project with the following structure:

```
terraform/
├── main.tf
├── variables.tf
├── outputs.tf
├── environments/
│   └── dev/
│       ├── main.tf
│       ├── variables.tf
│       └── backend.tf
└── modules/
    └── confluent/
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

- **modules/**: Contains reusable Terraform modules.
- **environments/**: Contains environment-specific configurations (e.g., dev, prod).
- **main.tf**: Root configuration file.
- **variables.tf**: Variable definitions.
- **outputs.tf**: Output values.

### Step 3.4: Create a Confluent Cloud Module

Navigate to `modules/confluent` and create `main.tf` with the following content:

```hcl
provider "confluent" {
  # Configuration for Confluent Cloud provider
}

resource "confluent_environment_v2" "env" {
  display_name = var.environment_name
}

resource "confluent_kafka_cluster" "cluster" {
  display_name   = var.cluster_name
  environment_id = confluent_environment_v2.env.id
  cloud          = var.cloud_provider
  region         = var.region
  availability   = "SINGLE_ZONE"
}
```

Define variables in `variables.tf`:

```hcl
variable "environment_name" {
  description = "Name of the Confluent Cloud environment"
  type        = string
}

variable "cluster_name" {
  description = "Name of the Confluent Cloud cluster"
  type        = string
}

variable "cloud_provider" {
  description = "Cloud provider for the Confluent cluster (e.g., aws, gcp, azure)"
  type        = string
}

variable "region" {
  description = "Region for the Confluent cluster"
  type        = string
}
```

Specify outputs in `outputs.tf`:

```hcl
output "environment_id" {
  description = "The ID of the Confluent Cloud environment"
  value       = confluent_environment_v2.env.id
}

output "cluster_id" {
  description = "The ID of the Confluent Cloud cluster"
  value       = confluent_kafka_cluster.cluster.id
}
```

### Step 3.5: Configure the Development Environment

Navigate to `environments/dev` and create `main.tf`:

```hcl
module "confluent" {
  source           = "../../modules/confluent"
  environment_name = "dev-environment"
  cluster_name     = "dev-cluster"
  cloud_provider   = "aws"
  region           = "us-west2"
}
```

Define variables in `variables.tf` if needed and configure the backend in `backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket = "your-terraform-state-bucket"
    key    = "dev/terraform.tfstate"
    region = "us-west-2"
  }
}
```

*Note: Replace the S3 backend configuration with your preferred backend.*

---

## 4. Initial Confluent Cloud Integration

We'll now integrate Confluent Cloud with Terraform and capture it within Backstage.

### Step 4.1: Configure Confluent Cloud Provider in Terraform

Ensure you have the Confluent Cloud provider configured. In the root `main.tf`, add:

```hcl
provider "confluent" {
  cloud_api_key    = var.confluent_cloud_api_key
  cloud_api_secret = var.confluent_cloud_api_secret
}
```

Define these sensitive variables in `variables.tf`:

```hcl
variable "confluent_cloud_api_key" {
  description = "API Key for Confluent Cloud"
  type        = string
  sensitive   = true
}

variable "confluent_cloud_api_secret" {
  description = "API Secret for Confluent Cloud"
  type        = string
  sensitive   = true
}
```

Store these credentials securely, e.g., using environment variables or a secrets manager.

### Step 4.2: Initialize and Apply Terraform Configuration

From the root of your Terraform project, navigate to the development environment and apply the configuration:

```bash
cd environments/dev
terraform init
terraform apply
```

Review the plan and confirm the creation of the Confluent Cloud environment and cluster.

### Step 4.3: Capture Terraform State in Backstage

Backstage can visualize Terraform states using plugins. We'll integrate the Terraform state to be visible within Backstage.

1. **Install the Terraform Plugin**:

   In your Backstage project, add the Terraform plugin:

   ```bash
   yarn add @backstage/plugin-terraform
   ```

2. **Configure the Plugin**:

   Update `app-config.yaml` to include the Terraform plugin settings:

   ```yaml
   terraform:
     providers:
       aws:
         accessKeyId: ${AWS_ACCESS_KEY_ID}
         secretAccessKey: ${AWS_SECRET_ACCESS_KEY}
         region: us-west-2
     state:
       backend: s3
       config:
         bucket: your-terraform-state-bucket
         key: dev/terraform.tfstate
         region: us-west-2
   ```

3. **Set Up Authentication**:

   Ensure that Backstage has access to the necessary AWS credentials to read the Terraform state.

4. **Add the Terraform Component to Backstage**:

   In Backstage, navigate to **Create** > **Component** and select **Terraform** as the type. Provide necessary details to link the Terraform state.

---

## 5. Validating the Setup

With everything configured, it's crucial to validate that changes in Backstage propagate correctly through GitHub Actions and Terraform.

### Step 5.1: Set Up GitHub Actions Workflow

Create a GitHub Actions workflow in your `backstage-automation` repository to apply Terraform changes automatically.

1. **Create Workflow File**:

   In `.github/workflows/terraform.yml`, add:

   ```yaml
   name: Terraform Apply

   on:
     push:
       branches:
         - main
       paths:
         - 'terraform/**'

   jobs:
     terraform:
       runs-on: ubuntu-latest

       steps:
         - name: Checkout
           uses: actions/checkout@v2

         - name: Setup Terraform
           uses: hashicorp/setup-terraform@v1
           with:
             terraform_version: 1.0.0

         - name: Terraform Init
           run: terraform init
           working-directory: ./terraform/environments/dev

         - name: Terraform Apply
           run: terraform apply -auto-approve
           working-directory: ./terraform/environments/dev
           env:
             CONFLUENT_CLOUD_API_KEY: ${{ secrets.CONFLUENT_CLOUD_API_KEY }}
             CONFLUENT_CLOUD_API_SECRET: ${{ secrets.CONFLUENT_CLOUD_API_SECRET }}
   ```

2. **Configure Secrets**:

   In your GitHub repository settings, add the necessary secrets:

   - `CONFLUENT_CLOUD_API_KEY`
   - `CONFLUENT_CLOUD_API_SECRET`
   - Any other required credentials (e.g., AWS credentials if using S3 backend)

### Step 5.2: Trigger a Change via Backstage

1. **Access Backstage**: Navigate to your Backstage instance.

2. **Navigate to the Terraform Plugin**: Find the Terraform component you added earlier.

3. **Initiate a Change**: For example, modify the cluster name or region.

4. **Submit the Change**: This should create a pull request in your GitHub repository.

### Step 5.3: Observe GitHub Actions Execution

1. **Review Pull Request**: Ensure that the pull request reflects the intended changes.

2. **Merge the Pull Request**: Upon merging, GitHub Actions should trigger the workflow.

3. **Check Workflow Logs**: Verify that the Terraform apply step runs successfully, provisioning or updating resources in Confluent Cloud.

4. **Confirm Changes in Backstage**: Refresh Backstage to see the updated state from Terraform.

---

## Conclusion

Congratulations! You've successfully set up a minimal Backstage instance integrated with GitHub and Terraform to manage Confluent Cloud resources. This setup enables you to automate the provisioning of Confluent Cloud environments and clusters directly from Backstage, streamlining your infrastructure management workflow.

In the next part of this series, we'll delve deeper into enhancing your Backstage setup with additional plugins, security configurations, and scaling strategies to handle larger scopes and more complex environments.

Stay tuned, and happy automating!

---

## Additional Resources

- [Backstage Documentation](https://backstage.io/docs)
- [Terraform Confluent Cloud Provider](https://registry.terraform.io/providers/confluentinc/confluent/latest/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Confluent Cloud Documentation](https://docs.confluent.io/cloud/current/overview.html)