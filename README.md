# stagecraft-infra

Terraform for the Stagecraft platform's AWS infrastructure. Deliberately
minimal, per explicit scope: just an EKS cluster, the IAM permissions each
service needs to run in it, and enough networking to expose it via a load
balancer. No RDS, ElastiCache, or SQS provisioning here — those are assumed
to already exist or be provisioned separately.

## Modules

| Module | Provisions |
|---|---|
| `modules/networking` | A VPC with public + private subnets across 2 AZs, one shared NAT gateway, route tables. Subnets are tagged for EKS/ELB auto-discovery. |
| `modules/eks` | The EKS cluster, a managed node group, and the IAM OIDC provider that IRSA roles trust. |
| `modules/iam` | One IRSA role per service (`stagecraft-webhook`, `stagecraft-worker`, `stagecraft-api`) scoped to exactly what that service calls (SQS, Bedrock, SES, optional KB S3), plus the AWS Load Balancer Controller's role. |

`stagecraft-mcp` has no AWS IAM needs (it only calls the GitHub API and stagecraft-api's internal HTTP endpoint), so it has no IRSA role here.

## Prerequisites

- An existing SQS queue (`stagecraft-webhooks`) — pass its ARN as `sqs_queue_arn`.
- Refresh `modules/iam/policies/aws-load-balancer-controller-policy.json` from the canonical source before a production apply (see `modules/iam/policies/README.md`).

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars   # fill in sqs_queue_arn
terraform init
terraform plan
terraform apply
```

After apply, install the AWS Load Balancer Controller and the Stagecraft services into the cluster via `stagecraft-helm`, using the role ARNs from `terraform output` as the `eks.amazonaws.com/role-arn` annotation on each service account.

## What's deliberately out of scope

Production-grade extras (multi-AZ NAT, RDS, ElastiCache, WAF, a Terraform state backend module, cost/security guardrails) are not included — this stack provisions exactly the cluster, permissions, and load-balancer path needed to run Stagecraft, nothing more.
