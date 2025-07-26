output "repository_urls" {
  description = "URLs of the ECR repositories"
  value = {
    for k, v in aws_ecr_repository.repositories : k => v.repository_url
  }
}

output "repository_arns" {
  description = "ARNs of the ECR repositories"
  value = {
    for k, v in aws_ecr_repository.repositories : k => v.arn
  }
}

output "repository_names" {
  description = "Names of the ECR repositories"
  value = {
    for k, v in aws_ecr_repository.repositories : k => v.name
  }
}

output "registry_id" {
  description = "Registry ID where the repositories are created"
  value       = data.aws_caller_identity.current.account_id
}