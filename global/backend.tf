terraform {
  backend "s3" {
    encrypt        = true
    dynamodb_table = "terraform-lock-${var.account_id}-macaozinho-${var.environment}"
  }
}