# stagecraft-infra

Terraform for the Stagecraft platform's AWS infrastructure, in **two stages**
because the second stage needs a live, reachable EKS cluster before its
`kubernetes`/`helm` providers can be configured — a well-known Terraform
constraint (a provider can't safely depend on a resource created in the same
apply). Every resource is named with the `stagecraft-` prefix (`var.cluster_name`,
default `"stagecraft"`).

## Stage 1 (root of this repo) — pure AWS resources

| Piece | What it provisions |
|---|---|
| `module.vpc` | [`terraform-aws-modules/vpc/aws`](https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws) — VPC, public+private subnets across 2 AZs, one shared NAT gateway. |
| `module.eks` | [`terraform-aws-modules/eks/aws`](https://registry.terraform.io/modules/terraform-aws-modules/eks/aws) — EKS cluster, managed node group, OIDC provider for IRSA. |
| `module.rds` (`modules/rds`) | Postgres (hand-rolled, not the registry module — see below) with `pgvector` support, master password auto-generated and stored in Secrets Manager (never a plain Terraform variable/output). |
| `module.elasticache` (`modules/elasticache`) | Redis, hand-rolled, TLS-in-transit + at-rest encryption (no AUTH token — connects via a plain `rediss://` URL, which `stagecraft-api`/`stagecraft-worker` already support). |
| `module.sqs` (`modules/sqs`) | The `stagecraft-webhooks` queue + a dead-letter queue (5 max receives before a message is parked for manual inspection). |
| `module.iam` (`modules/iam`) | One IRSA role per service (webhook/worker/api) scoped to exactly what it calls, plus the AWS Load Balancer Controller's role. |
| `module.secrets` (`modules/secrets`) | Every application credential (GitHub App, JWT/Fernet keys, computed `DATABASE_URL`/`REDIS_URL`/etc.) as 5 JSON secrets in Secrets Manager — `stagecraft-{api,worker,webhook,mcp,frontend}-secrets` — plus the IRSA role the External Secrets Operator uses to read them. Nothing here is ever a plain Terraform output. |

**Why RDS/ElastiCache are hand-rolled instead of registry modules**: for VPC and EKS, the registry modules are the extremely well-established, de facto standard (huge complexity reduction, very stable interfaces). For RDS/ElastiCache, the resources needed are simple enough that hand-rolling with core `aws_db_instance`/`aws_elasticache_replication_group` resources carries less risk than depending on a less-thoroughly-verified module interface — on a production account, correctness matters more than avoiding two dozen lines of code. **Verify the pinned module versions' interfaces still match after `terraform init` (run `terraform plan` and read it — do not blind-apply) before applying against a real account** — registry module APIs do shift between majors, and this was written without live access to check the current docs.

## Stage 2 (`cluster-bootstrap/`) — needs the live cluster

Reads stage 1's outputs via `terraform_remote_state` (local backend, relative path — no shared backend required, but also not multi-user safe; consider an S3+DynamoDB backend before a real team uses this). Provisions:

- The `stagecraft` namespace
- The AWS Load Balancer Controller (via `helm_release`, using stage 1's `lb_controller_role_arn`)
- The `external-secrets` namespace + the External Secrets Operator itself (via `helm_release`, its ServiceAccount annotated with stage 1's `eso_role_arn`)

Stage 2 no longer creates any Kubernetes `Secret` — it only installs the operator that will. **No credential ever passes through this stage's state or tfvars.**

## How secrets actually reach the pods

1. Stage 1's `module.secrets` writes every credential into 5 Secrets Manager entries, sourced from stage 1's own `terraform.tfvars` (gitignored, real values only there).
2. Stage 2 installs the External Secrets Operator, authenticated via IRSA (no static AWS keys).
3. `stagecraft-helm`'s umbrella chart installs one cluster-wide `ClusterSecretStore` (`templates/clustersecretstore.yaml`) pointing at Secrets Manager through that same IRSA identity.
4. Each of the 5 service charts renders an `ExternalSecret` (`templates/externalsecret.yaml`, driven by `common.externalSecret`) that pulls its JSON secret and materializes it as a Kubernetes `Secret` named `stagecraft-<service>-secrets` — exactly the name each Deployment already expects via `envFrom.secretRef`.

Change a credential by updating stage 1's `terraform.tfvars` and re-applying — ESO re-syncs the k8s Secret on its `refreshInterval` (default `1h`) without you ever touching the cluster directly.

## Usage

```bash
# Stage 1
cp terraform.tfvars.example terraform.tfvars   # fill in real GitHub App / key values, never commit
terraform init
terraform plan   # READ THIS before apply, especially the vpc/eks module diffs
terraform apply

# Stage 2 (after stage 1 succeeds)
cd cluster-bootstrap
terraform init
terraform plan
terraform apply

# Then, once ESO has synced the 5 Secrets (check with: kubectl get externalsecret -n stagecraft)
helm install stagecraft ../../stagecraft-helm -f ../../stagecraft-helm/values.yaml -f ../../stagecraft-helm/values-prod.yaml
```

## What's still not in Terraform

- **Bedrock model access** — not a resource to create; request access to the model behind `BEDROCK_MODEL_ID` in the Bedrock console for this account/region before any `bedrock:InvokeModel` call will succeed.
- **ACM certificate + Route53** — the Ingress resources in `stagecraft-helm` currently only serve HTTP (no `certificate-arn` annotation, no 443 listener). Add a cert + DNS before going further than a demo.
- **SES domain/email verification** — only needed for the "AI suggested a fix" email notifications (best-effort, app works without it).
- Refresh `modules/iam/policies/aws-load-balancer-controller-policy.json` from the canonical source before a production apply (see that folder's README).

## Cost note

Stage 1 alone (EKS control plane + 2× t3.medium nodes + 1 NAT gateway) runs roughly **$0.23–0.25/hr**. Adding the default-sized RDS (`db.t4g.micro`) and ElastiCache (`cache.t4g.micro`) adds roughly another **$0.05–0.06/hr** at single-AZ/single-node settings. Multi-AZ RDS and multi-node Redis roughly double their respective costs.
