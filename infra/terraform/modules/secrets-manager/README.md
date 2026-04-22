# secrets-manager module

Creates a single AWS Secrets Manager secret and initial version.

## Security notes

- Secret value is provided via a sensitive Terraform variable.
- Do not commit real secrets to `tfvars` files in git.
