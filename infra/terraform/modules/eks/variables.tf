variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where EKS resources are deployed."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for EKS control plane ENIs and worker nodes."
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "Provide at least two private subnet IDs for resilient EKS deployment."
  }
}

variable "node_instance_type" {
  description = "EC2 instance type for the managed node group."
  type        = string
  default     = "t3.medium"
}

variable "node_group_min_size" {
  description = "Minimum number of nodes in the managed node group."
  type        = number
  default     = 1
}

variable "node_group_desired_size" {
  description = "Desired number of nodes in the managed node group."
  type        = number
  default     = 2
}

variable "node_group_max_size" {
  description = "Maximum number of nodes in the managed node group."
  type        = number
  default     = 3
}
