variable "project_name" {
  description = "Project identifier used in resource tags."
  type        = string
}

variable "environment" {
  description = "Environment identifier used in resource tags."
  type        = string
}

variable "secret_name" {
  description = "Name of the secret to create."
  type        = string
}

variable "secret_value" {
  description = "Secret string payload. Pass via secure CI variable or TF_VAR."
  type        = string
  sensitive   = true
}
