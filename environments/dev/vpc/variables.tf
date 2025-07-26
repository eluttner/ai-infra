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

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/24"
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