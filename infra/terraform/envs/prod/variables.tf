variable "project_name" {
  description = "Project identifier used for naming and tagging."
  type        = string
  default     = "accel"
}

variable "environment" {
  description = "Deployment environment."
  type        = string
  default     = "prod"
}

variable "aws_region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR range for the production VPC."
  type        = string
  default     = "10.20.0.0/16"
}

variable "eks_deployment_secret_value" {
  description = "Secret payload for EKS deployment consumption (set securely, not in git)."
  type        = string
  sensitive   = true
}
