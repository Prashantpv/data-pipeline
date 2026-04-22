project_name = "accel"
environment  = "prod"
aws_region   = "us-east-1"
vpc_cidr     = "10.20.0.0/16"
# Set via secure CI secret or TF_VAR_eks_deployment_secret_value for real usage.
eks_deployment_secret_value = "replace-me-securely"
