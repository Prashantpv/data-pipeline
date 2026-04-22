output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "Private endpoint for the EKS API server."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_security_group_id" {
  description = "Cluster security group ID managed by EKS."
  value       = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}
