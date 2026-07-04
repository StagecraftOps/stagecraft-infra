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
# terraform-aws-modules/eks/aws — handles the OIDC provider + managed node
# group internally. Verify the `~> 20.0` interface after `terraform init`.
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  enable_irsa = true

  eks_managed_node_groups = {
    default = {
      instance_types = var.node_instance_types
      min_size       = var.node_min_size
      max_size       = var.node_max_size
      desired_size   = var.node_desired_size
      subnet_ids     = module.vpc.private_subnets
    }
  }

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
