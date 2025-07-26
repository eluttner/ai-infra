# Macaozinho AWS Infrastructure

This repository contains Terraform infrastructure code for the Macaozinho project, managing DEV and PROD environments across different AWS regions.

## Prerequisites

- AWS CLI v2.x or higher
- Terraform v1.5.x or higher
- Git
- Docker (for container builds)

## Initial AWS Account Setup

### 1. Configure AWS CLI
```bash
aws configure
# Enter your AWS Access Key ID, Secret Access Key, region, and output format
```

### 2. Verify AWS Account Access
```bash
aws sts get-caller-identity
```

## Route53 Domain Setup

Since you own the `macaozinho.lat` domain, you need to delegate subdomains to AWS Route53.

### Manual Route53 Configuration

1. **Create Hosted Zones in AWS Console**
   - Go to Route53 > Hosted Zones
   - Create hosted zone for `dev.macaozinho.lat`
   - Create hosted zone for `prod.macaozinho.lat`
   - Note the NS (nameserver) records for each hosted zone

2. **Update Domain Registrar**
   - Log into your domain registrar where `macaozinho.lat` is registered
   - Add NS records for subdomains:
     ```
     dev.macaozinho.lat  NS  ns-xxx.awsdns-xx.net
     dev.macaozinho.lat  NS  ns-xxx.awsdns-xx.org
     dev.macaozinho.lat  NS  ns-xxx.awsdns-xx.co.uk
     dev.macaozinho.lat  NS  ns-xxx.awsdns-xx.com
     
     prod.macaozinho.lat NS  ns-xxx.awsdns-xx.net
     prod.macaozinho.lat NS  ns-xxx.awsdns-xx.org
     prod.macaozinho.lat NS  ns-xxx.awsdns-xx.co.uk
     prod.macaozinho.lat NS  ns-xxx.awsdns-xx.com
     ```
   - Replace the `ns-xxx` values with actual nameservers from your hosted zones

3. **Verify Delegation**
   ```bash
   # Test subdomain delegation
   dig NS dev.macaozinho.lat
   dig NS prod.macaozinho.lat
   
   # Should return AWS nameservers
   ```

## Environment Configuration

### Sample terraform.tfvars

Create `terraform.tfvars` files in each environment directory:

**For DEV environment (`environments/dev/vpc/terraform.tfvars`):**
```hcl
project     = "macaozinho"
environment = "dev"
region      = "us-east-1"
cidr_block  = "10.0.0.0/24"

common_tags = {
  Project     = "macaozinho"
  Owner       = "UNDP"
  Environment = "dev"
  ManagedBy   = "terraform"
  CostCenter  = "macaozinho"
}
```

**For PROD environment (`environments/prod/vpc/terraform.tfvars`):**
```hcl
project     = "macaozinho"
environment = "prod"
region      = "us-east-2"
cidr_block  = "10.1.0.0/24"

common_tags = {
  Project     = "macaozinho"
  Owner       = "UNDP"
  Environment = "prod"
  ManagedBy   = "terraform"
  CostCenter  = "macaozinho"
}
```

## Backend Configuration

Before running Terraform, create S3 buckets and DynamoDB tables for state management:

```bash
# Get your AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create S3 buckets for state storage
aws s3 mb s3://${ACCOUNT_ID}-terraform-states-us-east-1 --region us-east-1
aws s3 mb s3://${ACCOUNT_ID}-terraform-states-us-east-2 --region us-east-2

# Create DynamoDB tables for state locking
aws dynamodb create-table \
  --table-name terraform-lock-${ACCOUNT_ID}-macaozinho-dev \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1

aws dynamodb create-table \
  --table-name terraform-lock-${ACCOUNT_ID}-macaozinho-prod \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-2
```

## OIDC Provider Setup

Before using GitHub Actions, create the OIDC provider in AWS:

```bash
# Create OIDC provider for GitHub Actions
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --client-id-list sts.amazonaws.com

# Note the ARN returned - you'll need it for role trust policies
```

## Deployment Instructions

### Deploy VPC Infrastructure

1. **Initialize and Deploy DEV VPC:**
```bash
cd environments/dev/vpc

# Initialize with backend configuration
terraform init \
  -backend-config="bucket=${ACCOUNT_ID}-terraform-states-us-east-1" \
  -backend-config="key=macaozinho/dev/vpc.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=terraform-lock-${ACCOUNT_ID}-macaozinho-dev"

terraform plan
terraform apply
```

2. **Initialize and Deploy PROD VPC:**
```bash
cd environments/prod/vpc

# Initialize with backend configuration
terraform init \
  -backend-config="bucket=${ACCOUNT_ID}-terraform-states-us-east-2" \
  -backend-config="key=macaozinho/prod/vpc.tfstate" \
  -backend-config="region=us-east-2" \
  -backend-config="dynamodb_table=terraform-lock-${ACCOUNT_ID}-macaozinho-prod"

terraform plan
terraform apply
```

### Deploy Application Infrastructure

1. **Deploy DEV Application:**
```bash
cd environments/dev/app

# Initialize with backend configuration
terraform init \
  -backend-config="bucket=${ACCOUNT_ID}-terraform-states-us-east-1" \
  -backend-config="key=macaozinho/dev/project.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="dynamodb_table=terraform-lock-${ACCOUNT_ID}-macaozinho-dev"

terraform plan
terraform apply
```

2. **Deploy PROD Application:**
```bash
cd environments/prod/app

# Initialize with backend configuration
terraform init \
  -backend-config="bucket=${ACCOUNT_ID}-terraform-states-us-east-2" \
  -backend-config="key=macaozinho/prod/project.tfstate" \
  -backend-config="region=us-east-2" \
  -backend-config="dynamodb_table=terraform-lock-${ACCOUNT_ID}-macaozinho-prod"

terraform plan
terraform apply
```

## Development Workflow

### Using Make Commands

```bash
# Format Terraform files
make fmt

# Validate Terraform configuration
make validate

# Generate cost estimation
make plan-cost
```

### New Developer Onboarding

1. Install prerequisites (AWS CLI, Terraform, Docker)
2. Configure AWS credentials
3. Clone this repository
4. Copy and customize `terraform.tfvars` files
5. Run `make validate` to verify setup
6. Deploy to DEV environment first

## Troubleshooting

### Common Issues

1. **S3 bucket already exists**: Bucket names must be globally unique
2. **DynamoDB table already exists**: Check if table already exists in region
3. **Route53 delegation not working**: Verify NS records at domain registrar
4. **Terraform state locked**: Check DynamoDB table for stuck locks

### Getting Help

- Check AWS CloudFormation events for resource creation failures
- Review Terraform logs with `TF_LOG=DEBUG`
- Verify IAM permissions for your AWS user/role

## GitHub Actions Workflow Example

Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy Infrastructure

on:
  push:
    branches: [main]
    paths: ['environments/**']
  pull_request:
    branches: [main]
    paths: ['environments/**']

env:
  AWS_REGION_DEV: us-east-1
  AWS_REGION_PROD: us-east-2

jobs:
  plan-dev:
    if: github.event_name == 'pull_request'
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
      pull-requests: write
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ~1.5.0
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/macaozinho-dev-github-actions-terraform
          aws-region: ${{ env.AWS_REGION_DEV }}
      
      - name: Terraform Plan DEV
        working-directory: ./environments/dev/vpc
        run: |
          terraform init
          terraform plan -no-color > plan.txt
          # Add plan output to PR comment

  deploy-dev:
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: ~1.5.0
      
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: arn:aws:iam::${{ secrets.AWS_ACCOUNT_ID }}:role/macaozinho-dev-github-actions-terraform
          aws-region: ${{ env.AWS_REGION_DEV }}
      
      - name: Deploy DEV Infrastructure
        working-directory: ./environments/dev/vpc
        run: |
          terraform init
          terraform apply -auto-approve
```

## Required IAM Permissions

Your AWS user/role needs these permissions for initial setup:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:CreateBucket",
        "s3:GetBucketVersioning",
        "s3:PutBucketVersioning",
        "s3:PutBucketEncryption",
        "dynamodb:CreateTable",
        "dynamodb:DescribeTable",
        "iam:CreateRole",
        "iam:CreateOpenIDConnectProvider",
        "route53:CreateHostedZone",
        "route53:ListHostedZones"
      ],
      "Resource": "*"
    }
  ]
}
```