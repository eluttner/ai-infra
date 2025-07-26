variable "project" {
  description = "Project name"
  type        = string
  default     = "macaozinho"
}

variable "environment" {
  description = "Environment name (dev, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "Environment must be either 'dev' or 'prod'."
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "account_id" {
  description = "AWS Account ID"
  type        = string
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