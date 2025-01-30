# Part 1: Setting Up Backstage and Initial Configuration

In this first post of our series, we’ll walk through how to:

1. **Create a GitHub repository** to store all code (Backstage, Terraform, GitHub Actions).
2. **Install Backstage** locally and configure it for your GitHub organization.
3. **Set up a Terraform project** to manage Confluent Cloud resources (Environment + Cluster).
4. **Create a GitHub Actions pipeline** that automatically applies Terraform changes.
5. **Integrate** your Terraform project into Backstage so you can provision Confluent Cloud resources in a self-service way.

By the end, you’ll have a **fully automated** pipeline that spins up a new Confluent Cloud Environment and Cluster with just a push to GitHub (triggered by Backstage).

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)  
2. [Set Up Your GitHub Repository](#2-set-up-your-github-repository)  
3. [Install and Configure Backstage](#3-install-and-configure-backstage)  
4. [Configure GitHub Integration in Backstage](#4-configure-github-integration-in-backstage)  
5. [Prepare Your Terraform Project](#5-prepare-your-terraform-project)  
6. [Set Up GitHub Actions](#6-set-up-github-actions)  
7. [Confluent Cloud Integration Details](#7-confluent-cloud-integration-details)  
8. [Add Backstage Catalog Entities for Terraform](#8-add-backstage-catalog-entities-for-terraform)  
9. [Validate the End-to-End Flow](#9-validate-the-end-to-end-flow)  
10. [Next Steps](#10-next-steps)

---

## 1. Prerequisites

Ensure you have the following ready:

- **Node.js v14+** (preferably v16+)
- **Yarn** (Classic) or **npm**
- **Git** (to commit and push your code)
- **Terraform v1.2+** (installed locally)
- A **GitHub Account** (a dedicated organization is ideal)
- A **Confluent Cloud** account with permission to create environments and clusters
- **Confluent Cloud API Keys** (Service Account or user-based) with the appropriate permissions for provisioning resources

> **Note on Credentials**: Make sure you have your **Confluent Cloud API Key** and **Secret** on hand. You will need these to authenticate Terraform against Confluent Cloud.

---

## 2. Set Up Your GitHub Repository

First, create (or choose) a GitHub repository that will contain:

1. **Backstage application** code.
2. **Terraform** configuration files.
3. **GitHub Actions** workflows.

### Steps

1. **Create a new repository** in your GitHub organization (or personal account).  
   - For example, name it: `backstage-confluent-selfservice`.
   - Initialize it with a `README.md` (we will update it with our instructions).

2. **Clone** the new repository locally:
   ```bash
   git clone https://github.com/<YOUR_ORG>/backstage-confluent-selfservice.git
   cd backstage-confluent-selfservice
   ```

3. You now have a local folder ready to hold both your Backstage code and your Terraform setup.

---

## 3. Install and Configure Backstage

We’ll bootstrap a new Backstage application. Follow the official [Backstage Getting Started Guide](https://backstage.io/docs/getting-started/) or run the command below:

```bash
# From the root of your cloned repository:
npx @backstage/create-app@latest
```

It will prompt you to provide:
- **App name** (e.g., `backstage-confluent-selfservice`)
- **Package manager** (Yarn or npm)
- **Database** selection (SQLite for local development is simplest)

Once generated, you’ll see a new folder (e.g., `backstage-confluent-selfservice`) in your repo.

### Folder Structure

Your repository should now look something like this:

```
.
└── backstage-confluent-selfservice/
    ├── packages/
    ├── app-config.yaml
    ├── yarn.lock
    ├── package.json
    └── (other auto-generated Backstage files)
```

### Running Backstage Locally

1. Navigate into the generated folder:
   ```bash
   cd backstage-confluent-selfservice
   ```

2. Install dependencies and run in development mode:
   ```bash
   yarn install
   yarn dev
   ```

3. Open your browser to [http://localhost:3000](http://localhost:3000) — you should see Backstage running.

### Commit and Push

```bash
git add .
git commit -m "Add initial Backstage application"
git push origin main
```

---

## 4. Configure GitHub Integration in Backstage

To let Backstage query GitHub (fetching catalog files, showing repositories, etc.):

1. **Create a GitHub Token** (Personal Access Token or GitHub App token).  
   - Go to **GitHub** > **Settings** > **Developer settings** > **Personal access tokens** > **Fine-Grained tokens**.  
   - Generate a token with **repo** (and possibly **read:org**) scopes.

2. **Set the Token as an Environment Variable** in your local development environment. For example:
   ```bash
   export GITHUB_TOKEN="<YOUR_GITHUB_PERSONAL_ACCESS_TOKEN>"
   ```
   Or store it in a `.env` file (remember not to commit `.env` to source control).

3. **Add GitHub Integration** to your Backstage `app-config.yaml`:

   ```yaml
   integrations:
     github:
       - host: github.com
         token: ${GITHUB_TOKEN}
   ```

> **Note**: For production or team setups, consider storing this token in a secret manager or environment variable in your CI/CD pipelines. Never commit tokens directly to the repo.

---

## 5. Prepare Your Terraform Project

We need a Terraform configuration that:

- Authenticates with Confluent Cloud.
- Creates a new **Confluent Cloud Environment**.
- Creates a **Kafka Cluster** in that environment.

### Create a `terraform` Folder

From the **root** of your GitHub repo (the same level as the `backstage-confluent-selfservice` folder):

```bash
mkdir terraform
cd terraform
touch main.tf variables.tf versions.tf
```

Your structure might look like this now:

```
.
├── backstage-confluent-selfservice/
│   └── (Backstage code)
└── terraform/
    ├── main.tf
    ├── variables.tf
    └── versions.tf
```

#### `versions.tf`

```hcl
terraform {
  required_version = ">= 1.2.0"
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "~> 1.33"
    }
  }
}
```

#### `variables.tf`

```hcl
variable "confluent_cloud_api_key" {
  type      = string
  sensitive = true
}

variable "confluent_cloud_api_secret" {
  type      = string
  sensitive = true
}

variable "environment_name" {
  type    = string
  default = "backstage-env"
}

variable "cluster_name" {
  type    = string
  default = "backstage-cluster"
}

variable "cloud_provider" {
  type    = string
  default = "gcp"
}

variable "region" {
  type    = string
  default = "us-central1"
}
```

#### `main.tf`

```hcl
provider "confluent" {
  api_key    = var.confluent_cloud_api_key
  api_secret = var.confluent_cloud_api_secret
}

# Create Confluent Environment
resource "confluent_environment" "env" {
  display_name = var.environment_name
}

# Create a Basic Cluster in that Environment
resource "confluent_kafka_cluster" "basic_cluster" {
  display_name         = var.cluster_name
  cloud               = var.cloud_provider
  region              = var.region
  availability        = "SINGLE_ZONE"
  environment_id      = confluent_environment.env.id
  kafka_cluster_type  = "BASIC"
}
```

### Optional: `backend.tf` (Remote State)

If you want to store the Terraform state file in a remote location (e.g., Terraform Cloud, AWS S3, GCS), create a `backend.tf` and configure accordingly. For a simple demo, local state is sufficient.

### Test Locally

1. In the `terraform` folder, run:
   ```bash
   terraform init
   terraform plan \
   -var "confluent_cloud_api_key=YOUR_KEY" \
   -var "confluent_cloud_api_secret=YOUR_SECRET"
   ```
2. You should see a plan indicating that Terraform will create a new environment and cluster in Confluent Cloud.  
3. For now, **do not apply** — we’ll let GitHub Actions handle that.

---

## 6. Set Up GitHub Actions

We want changes to the `terraform` folder to automatically trigger a **plan and apply**. Create a file at `.github/workflows/terraform.yaml` in your repo:

<details>
<summary>Click to expand <code>terraform.yaml</code> example</summary>

```yaml
name: "Terraform CI/CD"

on:
  push:
    branches:
      - main
  pull_request:
    branches:
      - main

jobs:
  terraform:
    runs-on: ubuntu-latest

    steps:
      - name: Check out code
        uses: actions/checkout@v3

      - name: Set up Terraform
        uses: hashicorp/setup-terraform@v2

      - name: Terraform Init
        working-directory: ./terraform
        run: terraform init

      - name: Terraform Plan
        working-directory: ./terraform
        run: terraform plan \
          -var "confluent_cloud_api_key=${{ secrets.CONFLUENT_CLOUD_API_KEY }}" \
          -var "confluent_cloud_api_secret=${{ secrets.CONFLUENT_CLOUD_API_SECRET }}"

      - name: Terraform Apply
        if: github.ref == 'refs/heads/main'
        working-directory: ./terraform
        run: terraform apply -auto-approve \
          -var "confluent_cloud_api_key=${{ secrets.CONFLUENT_CLOUD_API_KEY }}" \
          -var "confluent_cloud_api_secret=${{ secrets.CONFLUENT_CLOUD_API_SECRET }}"
```
</details>

### Store Secrets in GitHub

Go to your GitHub repo **Settings > Secrets and variables > Actions** and add:
- `CONFLUENT_CLOUD_API_KEY`
- `CONFLUENT_CLOUD_API_SECRET`

This ensures GitHub Actions can securely authenticate to Confluent Cloud.  

> **Important**: Never commit these secrets in plaintext to your repository.

---

## 7. Confluent Cloud Integration Details

To create the **API Keys** you stored in GitHub:
1. Log in to [Confluent Cloud](https://confluent.cloud/).
2. Go to **Cloud API keys** or create a **Service Account** with the necessary roles (Environment & Cluster Admin if you’re provisioning at that level).
3. Generate an **API Key** and **Secret** pair.
4. Copy them into your GitHub Secrets.

From now on, any push to `main` that modifies your Terraform code will cause GitHub Actions to run `plan` and then `apply` automatically if everything’s successful.

---

## 8. Add Backstage Catalog Entities for Terraform

So that Backstage can “see” this Terraform project as a **Component** in its catalog, create a `catalog-info.yaml` file in the **root** of your repo (or inside the `backstage-confluent-selfservice` folder). For instance:

```yaml
apiVersion: backstage.io/v1alpha1
kind: Component
metadata:
  name: confluent-provisioning
  description: "Terraform to provision Confluent Cloud environment & cluster"
  annotations:
    # Example annotation linking to your GitHub Actions
    # This can help visualize build status in Backstage
    "github.com/project-slug": "<YOUR_ORG>/<YOUR_REPO>" 
spec:
  type: service
  owner: your-team
  lifecycle: experimental
  links:
    - url: "https://github.com/<YOUR_ORG>/<YOUR_REPO>/tree/main/terraform"
      title: "Terraform Code"
```

Then, in your Backstage `app-config.yaml`, make sure you have a **catalog location** referencing this file:

```yaml
catalog:
  locations:
    - type: url
      target: "https://github.com/<YOUR_ORG>/<YOUR_REPO>/blob/main/catalog-info.yaml"
```

> Alternatively, you can add the location via the Backstage **Add to Catalog** UI if your organization allows.  

### Verify in Backstage
1. Restart your Backstage app if needed (`yarn dev` again).
2. Navigate to **Catalog** in the Backstage UI.
3. You should now see a **`confluent-provisioning`** component.

This lays the foundation for more advanced self-service flows, templates, and scaffolder actions in future posts.

---

## 9. Validate the End-to-End Flow

Let’s confirm everything is working:

1. **Run Backstage**:  
   ```bash
   cd backstage-confluent-selfservice
   yarn dev
   ```  
   Navigate to [http://localhost:3000](http://localhost:3000).

2. **Push a Terraform Change**:
   - From the repo root, open `terraform/variables.tf`.
   - Change `environment_name` or `cluster_name` to something new (e.g., `my-new-env`).
   - Commit and push:
     ```bash
     git add terraform/variables.tf
     git commit -m "Test new environment name"
     git push origin main
     ```

3. **Check GitHub Actions**:
   - Go to **Actions** tab in your GitHub repo. 
   - You should see the **Terraform CI/CD** workflow triggered.
   - The workflow will run `terraform plan` and then `apply`.

4. **Check Confluent Cloud**:
   - Once the workflow succeeds, log in to [Confluent Cloud](https://confluent.cloud/).
   - You should see a new **Environment** (`my-new-env`) and a **Basic Cluster** in your chosen region (e.g., `us-central1`).

> If everything worked, you have successfully integrated Backstage + GitHub + Terraform + Confluent Cloud!

---

## 10. Next Steps

**Congratulations**—you’ve set up a fully automated system for provisioning Confluent Cloud resources with Backstage as your single pane of glass!

In **Part 2**, we’ll build on this foundation by:
- Creating a **robust development pipeline** (branching strategies, environment promotions).
- Using **Backstage plugins** and **Scaffolder** to enable self-service provisioning for broader sets of Confluent components.

Eventually, we’ll cover:
1. **Scaling** this setup to include **Schema Registry, Connectors, and Flink** in Confluent Cloud.
2. Extending the same model to **Confluent Platform** for on-prem or hybrid scenarios.
3. Applying best practices for multi-environment, enterprise-grade deployments.

Stay tuned for the next installment, and **happy automating**!
