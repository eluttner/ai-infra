terraform {
  required_version = "~> 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket         = "ACCOUNT_ID-terraform-states-us-east-1"
    key            = "macaozinho/dev/vpc.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-lock-ACCOUNT_ID-macaozinho-dev"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = merge(var.common_tags, {
      Environment = var.environment
    })
  }
}

module "vpc" {
  source = "../../../modules/vpc"

  project     = var.project
  environment = var.environment
  cidr_block  = var.vpc_cidr
  common_tags = merge(var.common_tags, {
    Environment = var.environment
  })
}