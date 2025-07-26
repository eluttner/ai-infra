variable "project" {
  description = "Project name"
  type        = string
  default     = "macaozinho"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "ecr_repositories" {
  description = "List of ECR repository names to create"
  type        = list(string)
  default     = ["monday-webhook", "file-upload"]
}

variable "max_image_count" {
  description = "Maximum number of images to keep in repository"
  type        = number
  default     = 10
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default = {
    Project     = "macaozinho"
    Owner       = "UNDP"
    ManagedBy   = "terraform"
    CostCenter  = "macaozinho"
  }
}