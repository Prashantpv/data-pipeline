output "vpc_id" {
  description = "Production VPC ID."
  value       = module.network.vpc_id
}

output "public_subnet_ids" {
  description = "Production public subnet IDs."
  value       = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Production private subnet IDs."
  value       = module.network.private_subnet_ids
}

output "eks_cluster_name" {
  description = "Production EKS cluster name."
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Production EKS cluster API endpoint."
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_security_group_id" {
  description = "Production EKS cluster security group ID."
  value       = module.eks.cluster_security_group_id
}

output "eks_deployment_secret_arn" {
  description = "ARN of the deployment secret stored in Secrets Manager."
  value       = module.app_secret.secret_arn
}

output "eks_deployment_secret_name" {
  description = "Name of the deployment secret stored in Secrets Manager."
  value       = module.app_secret.secret_name
}
