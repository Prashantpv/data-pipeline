# DECISIONS

This document captures the main implementation trade-offs for the take-home
assignment, including where AI assistance was used and what was changed after
generation.

## 1. Private EKS API endpoint over public access

Decision:
The EKS cluster is configured with private endpoint access enabled and public
endpoint access disabled.

Why:
This is the safer production default for a security-first platform. It reduces
the attack surface of the Kubernetes control plane and aligns with a
deny-by-default posture.

Trade-off:
This makes operations and CI/CD more opinionated. GitHub-hosted runners usually
cannot reach a private-only EKS endpoint, so deployment requires either a
self-hosted runner with VPC connectivity, a VPN/bastion path, or a different
cluster endpoint posture for non-production environments.

Why I accepted it:
For this assignment, I prioritized security posture over convenience and called
out the operational consequence in the README.

## 2. Single NAT gateway instead of one NAT per AZ

Decision:
The VPC spans 2 AZs with public and private subnets, but uses a single NAT
gateway.

Why:
This keeps the design realistic while avoiding unnecessary cost for a small
service. The assignment asked for production-ready infrastructure, but did not
require full multi-AZ egress fault tolerance.

Trade-off:
A single NAT gateway is cheaper and simpler, but it creates an AZ-level
resilience gap for outbound traffic. If the NAT gateway or its AZ becomes
unavailable, workloads in private subnets may lose internet egress.

Why I accepted it:
I wanted to show awareness of the cost/reliability trade-off explicitly rather
than silently choosing the most expensive default.

## 3. Managed EKS node group over Fargate or self-managed nodes

Decision:
The platform uses one EKS managed node group in private subnets.

Why:
Managed node groups reduce operational burden while still allowing control over
instance type, scaling bounds, IAM, and upgrade behavior. This is a strong
middle ground for a small platform team.

Trade-off:
Self-managed nodes provide more flexibility, and Fargate can reduce node
management further, but both come with different operational and cost
trade-offs. Managed node groups are the clearest baseline for this assignment.

Why I accepted it:
The requirement explicitly asked for one managed node group, and this option
best balances maintainability and production realism.

## 4. Lightweight Prometheus stack over full kube-prometheus-stack

Decision:
Observability is implemented with a lightweight Prometheus deployment and
application-focused SLI alerts instead of a larger all-in-one monitoring stack.

Why:
The application already exposes Prometheus metrics, so a smaller Prometheus
setup is enough to demonstrate observability from day one. The alerts focus on
availability, latency, and 5xx error rate, which are the most defensible SLIs
for a request/response service.

Trade-off:
This keeps the footprint small and the configuration easy to understand, but it
does not provide the broader ecosystem that comes with kube-prometheus-stack,
such as default dashboards, service monitors, and more cluster-wide telemetry.

Why I accepted it:
For a time-boxed take-home, a lean setup better demonstrates intentional design
than installing a large stack without tailoring it.

## 5. Secrets stored in AWS Secrets Manager but consumed indirectly in-cluster

Decision:
Terraform provisions the AWS Secrets Manager secret, while the Helm chart
expects a Kubernetes Secret reference to be synced into the cluster by an
external mechanism such as External Secrets.

Why:
This separates secret ownership from application deployment and avoids embedding
secret values in Helm values, Kubernetes manifests, or GitHub Actions.

Trade-off:
This is more secure and closer to a production pattern, but the end-to-end
secret sync is intentionally documented rather than fully implemented in this
submission. That leaves one integration boundary outside the repo.

Why I accepted it:
The assignment required one secret in Secrets Manager and a documented rotation
strategy, not a full secret operator implementation. I chose to keep the
boundary explicit rather than overbuilding.

Rotation strategy:
Secrets should rotate in AWS Secrets Manager on a fixed cadence or on-demand
after suspected exposure. A controller such as External Secrets should refresh
the Kubernetes Secret from Secrets Manager, and workloads should be restarted
through a controlled rollout after rotation if the application does not support
live reload. Rotation ownership should sit with the platform team, while
application teams consume the secret through stable environment variable names
instead of secret-version-specific references.

## AI usage

I used AI assistance for both the sample application and parts of the platform
scaffolding, then reviewed and modified the output before treating it as part
of the submission.

What I accepted:
- The basic FastAPI service structure with `/healthz` and `/process`
- The initial multi-stage Dockerfile shape
- The first-pass Terraform/Helm/GitHub Actions scaffolding

What I changed or validated manually:
- Tightened the security posture toward private EKS access, non-root containers,
  restricted Pod Security labels, and deny-by-default NetworkPolicy behavior
- Checked that the infrastructure was organized as reusable Terraform modules
- Kept observability focused on SLI-based alerts rather than generic CPU or
  memory thresholds
- Reviewed the workflow and documentation so operational caveats are called out
  instead of hidden

What I rejected:
- Any suggestion to hardcode secrets in repository files or deployment manifests
- Any design that depended on long-lived AWS access keys in CI/CD
- Any observability setup that added significant bulk without improving the
  assignment outcome
