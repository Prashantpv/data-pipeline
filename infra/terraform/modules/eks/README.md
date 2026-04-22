# eks module

Minimal production-grade EKS module.

## What it creates

- EKS cluster with dedicated IAM role
- IRSA OIDC provider for service accounts
- One managed node group in private subnets
- Least-privilege node and cluster IAM policy attachments

## Security decisions

- Kubernetes API endpoint uses private access only (`endpoint_public_access = false`)
- No hardcoded account-specific ARNs
- No Kubernetes provider resources or workload deployment in this module
