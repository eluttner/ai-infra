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

variable "repositories" {
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
  default     = {}
}