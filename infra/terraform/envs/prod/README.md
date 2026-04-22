# Production Environment (`prod`)

This directory composes production infrastructure from reusable Terraform modules.

## Prerequisites

- Terraform `>= 1.8.0`
- AWS credentials with permissions for planned resources
- Remote backend configuration file (for example, `backend.hcl`)

## Usage

Run all commands from this directory:

```bash
terraform init -backend-config=backend.hcl
terraform fmt -check -recursive
terraform validate
terraform plan -var-file=prod.tfvars -out=tfplan
terraform apply tfplan
```

## Notes

- `prod.tfvars` contains baseline production defaults.
- Backend values are intentionally not hardcoded in code.
- Current composition wires only the `network` module.
