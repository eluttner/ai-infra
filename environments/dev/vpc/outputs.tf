output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "subnet_id" {
  description = "ID of the main subnet"
  value       = module.vpc.subnet_id
}

output "route53_zone_id" {
  description = "ID of the Route53 hosted zone"
  value       = module.vpc.route53_zone_id
}

output "route53_zone_name_servers" {
  description = "Name servers for the Route53 hosted zone"
  value       = module.vpc.route53_zone_name_servers
}