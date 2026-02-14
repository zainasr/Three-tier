# Bootstrap: GitHub OIDC and IAM role for CI/CD

Run this **once** (e.g. from your machine with `aws configure` or `terraform` profile) to create:

1. **GitHub OIDC identity provider** in your AWS account (if not already present).
2. **IAM role** that GitHub Actions can assume (no long-lived keys).

Then add the role ARN to your GitHub repo as secret **`AWS_ROLE_ARN`**.

## Prerequisites

- AWS CLI configured (e.g. `profile = terraform`, region `ap-south-1`).
- Terraform installed.

## Steps

1. Set your GitHub repo (owner/repo):

   ```bash
   export TF_VAR_github_repo = "your-username/your-repo"   # e.g. myorg/3-tier
   ```

2. From this directory:

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

3. Copy the role ARN from output:

   ```bash
   terraform output github_actions_role_arn
   ```

4. In GitHub: **Settings → Secrets and variables → Actions** → **New repository secret**:
   - Name: `AWS_ROLE_ARN`
   - Value: the ARN from step 3.

After that, the Terraform and App workflows can assume this role via OIDC (no access keys).

## State

Bootstrap uses **local backend** by default so you don't need S3 state for this one-time setup. If you prefer remote state, add a `backend "s3"` block and run `terraform init -reconfigure`.
