# Terraform Best Practices for Macaozinho Project

This document outlines Terraform best practices and conventions specific to the Macaozinho AWS infrastructure project.

## Project Structure & Organization

### Directory Structure
```
environments/           # Environment-specific configurations
├── dev/               # Development environment
│   ├── vpc/           # VPC infrastructure
│   └── app/           # Application infrastructure (ECR, IAM, etc.)
└── prod/              # Production environment
    ├── vpc/           # VPC infrastructure  
    └── app/           # Application infrastructure

modules/               # Reusable Terraform modules
├── vpc/              # VPC module
├── ecr/              # ECR module
├── dynamodb/         # DynamoDB module
└── s3-storage/       # S3 module

global/               # Global configurations
├── backend.tf        # Remote state configuration
├── providers.tf      # Provider configurations
└── versions.tf       # Version constraints
```

### State Management
- **Separate states**: VPC and application infrastructure use different state files
- **Environment isolation**: Each environment has its own state bucket and DynamoDB table
- **Naming convention**: 
  - S3: `{account-id}-terraform-states-{region}`
  - DynamoDB: `terraform-lock-{account-id}-{project}-{environment}`
  - State keys: `{project}/{environment}/{component}.tfstate`

## Code Standards

### File Organization
Each Terraform directory should contain:
- `main.tf` - Primary resource definitions
- `variables.tf` - Input variable declarations
- `outputs.tf` - Output value declarations  
- `terraform.tfvars` - Variable value assignments
- `versions.tf` - Provider version constraints

### Naming Conventions
- **Resources**: `{project}-{environment}-{service}` (e.g., `macaozinho-dev-vpc`)
- **Variables**: Use descriptive snake_case names
- **Modules**: Use kebab-case for module names
- **Tags**: All resources must include `common_tags`

### Variable Definitions
```hcl
# Good: Descriptive with validation
variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be either 'dev' or 'prod'."
  }
}

# Good: Default values for optional parameters
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/24"
}
```

### Resource Tagging
```hcl
# Always use common_tags variable
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  
  tags = merge(var.common_tags, {
    Name = "${var.project}-${var.environment}-vpc"
    Type = "networking"
  })
}
```

## Security Best Practices

### State File Security
- Store state in S3 with encryption enabled
- Use DynamoDB for state locking
- Restrict access with IAM policies
- Enable versioning on state buckets

### IAM Policies
- Follow principle of least privilege
- Use specific resource ARNs when possible
- Separate roles for different functions (ECR, Terraform, admin)
- Use OIDC for GitHub Actions authentication

### Secrets Management
- Never store secrets in Terraform code
- Use AWS Parameter Store or Secrets Manager
- Reference secrets by ARN in Terraform

## Module Development

### Module Structure
```
modules/vpc/
├── main.tf           # Resource definitions
├── variables.tf      # Input variables
├── outputs.tf        # Output values
├── README.md         # Module documentation
└── examples/         # Usage examples
```

### Module Best Practices
- Make modules reusable across environments
- Use semantic versioning for module releases
- Provide comprehensive documentation
- Include validation for critical variables
- Use data sources for lookups instead of hardcoded values

### Module Example
```hcl
# modules/vpc/main.tf
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name = "${var.project}-${var.environment}-vpc"
  })
}

# Output important values for other modules
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}
```

## Environment Management

### Environment Configuration
- Use `terraform.tfvars` files for environment-specific values
- Keep sensitive values in AWS Parameter Store
- Use different AWS regions for dev/prod isolation
- Implement proper access controls per environment

### Terraform Workspaces
```bash
# Don't use workspaces for environment separation
# Use separate directories and state files instead
# This provides better isolation and clearer organization
```

## CI/CD Integration

### GitHub Actions Best Practices
- Use OIDC authentication (no long-lived credentials)
- Separate workflows for plan and apply
- Require manual approval for production deployments
- Store Terraform plans as artifacts for review

### Workflow Structure
```yaml
# Plan on PR
- Terraform fmt check
- Terraform validate
- Terraform plan
- Comment plan on PR

# Apply on merge to main
- Terraform apply (dev environment)
- Manual approval gate
- Terraform apply (prod environment)
```

## Cost Management

### Cost Optimization
- Use `terraform plan -detailed-exitcode` for cost estimation
- Implement resource tagging for cost allocation
- Regular review of unused resources
- Use appropriate instance sizes and storage classes

### Resource Lifecycle
```hcl
# Example: ECR lifecycle policy
resource "aws_ecr_lifecycle_policy" "main" {
  repository = aws_ecr_repository.main.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus = "any"
        countType = "imageCountMoreThan"
        countNumber = 10
      }
      action = {
        type = "expire"
      }
    }]
  })
}
```

## Error Handling & Debugging

### Common Issues
- State locking conflicts: Check DynamoDB table for stuck locks
- Resource naming conflicts: Ensure unique names across regions
- Permission errors: Verify IAM roles and policies
- Backend initialization: Confirm S3 bucket and DynamoDB table exist

### Debugging Commands
```bash
# Enable detailed logging
export TF_LOG=DEBUG
export TF_LOG_PATH=terraform.log

# Validate configuration
terraform validate

# Format code
terraform fmt -recursive

# Show state
terraform show

# Import existing resources
terraform import aws_vpc.main vpc-12345678
```

## Project-Specific Guidelines

### Macaozinho Conventions
- **Project name**: Always use "macaozinho"
- **Environments**: Only "dev" and "prod"
- **Regions**: us-east-1 (dev), us-east-2 (prod)
- **CIDR blocks**: 10.0.0.0/24 (dev), 10.1.0.0/24 (prod)

### ECR Repository Naming
- Format: `{project}-{environment}-{service}`
- Examples: 
  - `macaozinho-dev-monday-webhook`
  - `macaozinho-prod-file-upload`

### Required Tags
```hcl
common_tags = {
  Project     = "macaozinho"
  Owner       = "UNDP"
  Environment = var.environment
  ManagedBy   = "terraform"
  CostCenter  = "macaozinho"
}
```

## Development Workflow

### Before Committing
1. Run `terraform fmt -recursive`
2. Run `terraform validate` 
3. Run `terraform plan` and review changes
4. Ensure all resources have proper tags
5. Update documentation if needed

### Code Review Checklist
- [ ] Resources follow naming conventions
- [ ] All resources are properly tagged
- [ ] No hardcoded values (use variables)
- [ ] No secrets in code
- [ ] Module documentation updated
- [ ] Plan output reviewed for unexpected changes

### Commands to Remember
```bash
# Format all files
make fmt

# Validate configuration  
make validate

# Plan with cost estimation
make plan-cost

# Apply with auto-approve (only for dev)
terraform apply -auto-approve

# Destroy resources (be careful!)
terraform destroy
```

This document should be updated as the project evolves and new best practices are identified.