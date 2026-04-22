terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  # Backend is intentionally partial. Provide concrete values via
  # backend config during init (for example, -backend-config=backend.hcl).
  backend "s3" {}
}
