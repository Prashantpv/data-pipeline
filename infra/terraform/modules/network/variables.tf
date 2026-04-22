variable "project_name" {
  description = "Project identifier used in resource tags."
  type        = string
}

variable "environment" {
  description = "Environment identifier used in resource tags."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "az_count" {
  description = "Number of Availability Zones to use."
  type        = number
  default     = 2

  validation {
    condition     = var.az_count >= 2
    error_message = "az_count must be at least 2 for production-grade baseline resilience."
  }
}
