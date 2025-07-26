# Macaozinho AWS Infrastructure

## Project Overview
- **Project**: macaozinho
- **Environments**: DEV (us-east-1), PROD (us-east-2)
- **Naming Convention**: `macaozinho-{env}-{service}`
- **Terraform Version**: ~> 1.5.0
- **AWS Provider**: ~> 5.0

## Infrastructure Components

### Core Infrastructure
- **VPC**: Single-AZ per environment (10.0.0.0/24 dev, 10.1.0.0/24 prod)
- **Route53**: Hosted zones for dev/prod.macaozinho.lat
- **IAM**: Environment-specific admin and GitHub Actions roles

### Current Modules
- **ECR**: Container repositories for monday-webhook and file-upload
  - Lifecycle policy: max 10 images, delete untagged after 1 day

### Future Modules (Planned)
- **Lambda**: Serverless functions for application logic
- **DynamoDB**: NoSQL database for application data
- **S3-Vector**: Vector storage for AI/ML workloads
- **Bedrock**: AWS AI/ML services integration

## State Management
- **S3 Buckets**: `{account-id}-terraform-states-{region}`
- **DynamoDB Tables**: `terraform-lock-{account-id}-macaozinho-{env}`
- **State Keys**: 
  - `macaozinho/{env}/vpc.tfstate`
  - `macaozinho/{env}/project.tfstate`

## GitHub Actions
- **Authentication**: OIDC (no long-lived credentials)
- **Repository**: `undp-org/*`
- **Current Workflow**: Container builds without deployment
- **Future Workflow**: Infrastructure deployment with Lambda updates
- **Triggers**: 
  - Push to main → deploy to dev
  - Tagged releases → deploy to prod (with approval)
  - PRs → tests and plan

## Required Tags
```hcl
common_tags = {
  Project     = "macaozinho"
  Owner       = "UNDP"
  Environment = var.environment
  ManagedBy   = "terraform"
  CostCenter  = "macaozinho"
}
```

## Directory Structure
```
environments/{dev,prod}/{vpc,app}/
modules/
├── vpc/                    # Current
├── ecr/                    # Current  
├── dynamodb/               # Future
├── s3-storage/             # Future
├── s3-vector/              # Future
├── lambda/                 # Future
└── bedrock/                # Future
global/{backend,providers,versions}.tf
scripts/{deploy,destroy,validate}.sh
```

## Security Notes
- State files encrypted at rest in S3
- OIDC authentication for GitHub Actions
- No security groups (containers handle own security)
- Separate Terraform states for VPC and application infrastructure

---
*See README.md for detailed setup instructions and CLAUDE.md for best practices*