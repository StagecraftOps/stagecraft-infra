data "aws_availability_zones" "available" {
  state = "available"
}

# --- Networking ---
# terraform-aws-modules/vpc/aws — the de facto standard VPC module. Verify the
# `~> 5.0` interface still matches after `terraform init` (module major
# versions occasionally rename arguments) before trusting `terraform plan`.
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.cluster_name}-vpc"
  cidr = var.vpc_cidr
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)

  public_subnets  = [cidrsubnet(var.vpc_cidr, 4, 0), cidrsubnet(var.vpc_cidr, 4, 1)]
  private_subnets = [cidrsubnet(var.vpc_cidr, 4, 2), cidrsubnet(var.vpc_cidr, 4, 3)]

  enable_nat_gateway   = true
  single_nat_gateway   = true # one shared NAT, not one per AZ — keeps cost/complexity down for demo scale
  enable_dns_hostnames = true
  enable_dns_support   = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }

  tags = { Name = "${var.cluster_name}-vpc" }
}

# --- EKS ---
# Hand-rolled (not the terraform-aws-modules/eks registry module) — that
# module resolves the calling identity's IAM role client-side via
# aws_iam_session_context, which needs iam:GetRole on your own role.
# PowerUserAccess (and similar restricted permission sets) don't grant that,
# with no way to opt out of the module's lookup. The native
# access_config.bootstrap_cluster_creator_admin_permissions flag below
# achieves the same "creator gets cluster admin" outcome entirely
# server-side, with no IAM introspection required. See modules/eks.
module "eks" {
  source = "./modules/eks"

  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  node_instance_types = var.node_instance_types
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
  node_desired_size   = var.node_desired_size

  tags = { Name = var.cluster_name }
}

# --- RDS (Postgres, hand-rolled — see modules/rds for why) ---
module "rds" {
  source = "./modules/rds"

  name                      = var.cluster_name
  vpc_id                    = module.vpc.vpc_id
  subnet_ids                = module.vpc.private_subnets
  allowed_security_group_id = module.eks.node_security_group_id

  engine_version        = var.rds_engine_version
  instance_class        = var.rds_instance_class
  allocated_storage     = var.rds_allocated_storage
  multi_az              = var.rds_multi_az
  backup_retention_days = var.rds_backup_retention_days
  skip_final_snapshot   = var.rds_skip_final_snapshot
}

# --- ElastiCache (Redis, hand-rolled — see modules/elasticache for why) ---
module "elasticache" {
  source = "./modules/elasticache"

  name                      = var.cluster_name
  vpc_id                    = module.vpc.vpc_id
  subnet_ids                = module.vpc.private_subnets
  allowed_security_group_id = module.eks.node_security_group_id

  engine_version     = var.redis_engine_version
  node_type          = var.redis_node_type
  num_cache_clusters = var.redis_num_cache_clusters
}

# --- SQS ---
module "sqs" {
  source = "./modules/sqs"

  name = var.cluster_name
}

# --- Per-service IRSA roles ---
module "iam" {
  source = "./modules/iam"

  cluster_name      = var.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.cluster_oidc_issuer_url
  namespace         = var.namespace
  sqs_queue_arn     = module.sqs.queue_arn
  kb_s3_bucket_arn  = var.kb_s3_bucket_arn
}

# --- Per-service secrets in Secrets Manager (synced to k8s by the External
# Secrets Operator, installed in stage 2 — see modules/secrets) ---
module "secrets" {
  source = "./modules/secrets"

  cluster_name      = var.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.cluster_oidc_issuer_url
  namespace         = var.namespace

  rds_endpoint                   = module.rds.endpoint
  rds_port                       = module.rds.port
  rds_db_name                    = module.rds.db_name
  rds_master_username            = module.rds.master_username
  rds_master_password_secret_arn = module.rds.master_password_secret_arn

  redis_primary_endpoint = module.elasticache.primary_endpoint
  redis_port             = module.elasticache.port

  sqs_queue_url = module.sqs.queue_url

  github_client_id       = var.github_client_id
  github_client_secret   = var.github_client_secret
  github_webhook_secret  = var.github_webhook_secret
  github_app_id          = var.github_app_id
  github_app_private_key = var.github_app_private_key
  github_app_slug        = var.github_app_slug
  allowed_org            = var.allowed_org
  secret_key             = var.secret_key
  token_encryption_key   = var.token_encryption_key
  internal_api_key       = var.internal_api_key
  nextauth_secret        = var.nextauth_secret
  ses_from_email         = var.ses_from_email
  frontend_url           = var.frontend_url
  bedrock_model_id       = var.bedrock_model_id
}
