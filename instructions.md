# Claude AWS Terraform

## Instructions

Include documentation to setup aws and to run each environment

All configurations from terraform vars

## Project
- Environments: DEV, PROD
- Project name: macaozinho
- Resource Naming Convention: `macaozinho-{env}-{service}`
- Tags:

```
common_tags = {
    Project     = "macaozinho"
    Owner       = "UNDP"
    Environment = var.environment
    ManagedBy   = "terraform"
    CostCenter  = "macaozinho"
}
```

### TERRAFORM

- Add all info to readme.md to do the inital setup and configure aws in a brand new account

- global configuration to include shared resources like Route53 hosted zones
    
- Manage terraform state & lock with s3 and dynamoBD for each ENVIRONMENT

### VPC
- module for VPC configuration since each environment
- Create a VPC specific for each ENVIRONMENT, get the project name from global
  1. What should be the CIDR block range for the VPCs? /16
     1.  DEV: 10.0.0.0/24, 
     2.  Prod: 10.1.0.0/24
  2. Use different ranges for each ENVIRONMENT
  3. Not multi-az

- PROD: us-east-2
- DEV: us-east-1

- S3 Terraform state: 
  - {account-id}-terraform-states-{region}/{var.project}/{var.environment}/vpc.tfstate
  - {account-id}-terraform-states-{region}/{var.project}/{var.environment}/project.tfstate

- DynamoDB Lock use one table for each environmet
  - terraform-lock-{account-id}-{var.project}-{var.environment}
  
### ROLES
- Create of roles for each environment: DEV, PROD, 
  - role admin (all roles)
  - role cicd (ecr)

#### GitHub Actions OIDC Roles
##### Role: {project}-{env}-github-actions-ecr
- Purpose: Allow GitHub Actions to push/pull container images
- Permissions:
  - ecr:GetAuthorizationToken
  - ecr:BatchCheckLayerAvailability
  - ecr:GetDownloadUrlForLayer
  - ecr:BatchGetImage
  - ecr:InitiateLayerUpload
  - ecr:UploadLayerPart
  - ecr:CompleteLayerUpload
  - ecr:PutImage
- Trust relationship: GitHub OIDC provider
- Condition: Repository must be undp-org/*

### Route53: 
- domains for the hosted zone
  - prod.macaozinho.lat
  - dev.macaozinho.lat

### GitHub Actions CI/CD
#### OIDC Configuration
- Connect with OIDC for keyless authentication
- GitHub repository: https://github.com/undp-org/*
- OIDC provider ARN: arn:aws:iam::{account-id}:oidc-provider/token.actions.githubusercontent.com
- Subject conditions: repo:undp-org/{repository-name}:*

<!-- #### CI/CD Workflow Requirements
1. **Build Phase**
   - Build Docker images for Lambda containers
   - Run tests and security scans
   - Tag images with:
   -  Git SHA and 
   -  environment
   -  'latest'

2. **Push Phase**
   - Authenticate to ECR using OIDC role
   - Push images to appropriate ECR repositories
   - Update image tags -->

<!-- 3. **Deploy Phase**
   - Update Lambda functions with new image URIs
   - Deploy Terraform infrastructure changes
   - Run smoke tests -->

### ECR
- creat two ECR repositories
- Repositories: 
  
### ECR (Elastic Container Registry)
#### Container Repositories
- Repository names: 
  - {var.project}-{var.environment}-stacks-monday
  - {var.project}-{var.environment}-stacks-file_upload

<!-- - Enable image scanning on push for security -->
- Set lifecycle policies to manage image retention

#### GitHub Actions Integration
- ECR repositories must be accessible by GitHub Actions
- Use OIDC (OpenID Connect) for secure authentication
- GitHub Actions will:
  1. Build Docker images
  2. Push images to ECR repositories
  3. Deploy infrastructure changes via Terraform

#### Image Management
- Tag images with Git commit SHA and environment
- Implement proper image cleanup policies
- Maximum 10 images per repository (configurable)
- Delete untagged images after 1 day

#### Workflow Triggers
- Push to main branch → deploy to dev
- Tagged releases → deploy to prod
- Pull requests → run tests and plan

#### Security Requirements
- All workflows must use OIDC authentication
- No long-lived AWS credentials in GitHub secrets
- Separate roles for different operations (ECR, Terraform)
- Environment-specific deployments with approval gates for prod


### Makefile
- tasks for: 
  - formatting (`terraform fmt`), 
  - linting (`terraform validate`)
  - cost estimation (`terraform plan -detailed-exitcode`)
  
### Readme.md
- Include explicit AWS CLI and Terraform version requirements, 
- sample `terraform.tfvars`
- onboarding instructions for new developers

## .gitignore
- python
- golang
- terraform
- .env
- worspace.md

### Folder structure below
/vpc/
/app/ for all other services
```
environments/ 
	dev/
		vpc/
			main.tf
			variables.tf
			terraform.tfvars
			outputs.tf
		app/
			main.tf
			variables.tf
			terraform.tfvars
			outputs.tf
	prod/ 
		vpc/
			main.tf
			variables.tf
			terraform.tfvars
			outputs.tf
		app/
			main.tf
			variables.tf
			terraform.tfvars
			outputs.tf
modules/ 
	vpc/
		main.tf 
		variables.tf 
		outputs.tf
	dynamodb/
		main.tf 
		variables.tf 
		outputs.tf
	ecr/
		main.tf 
		variables.tf 
		outputs.tf
	s3-storage/
		main.tf 
		variables.tf 
		outputs.tf
global/ 
	backend.tf 
	providers.tf 
	versions.tf
scripts/ 
	deploy.sh 
	destroy.sh 
	validate.sh
README.md
.gitignore
.github/workflows
Makefile
```