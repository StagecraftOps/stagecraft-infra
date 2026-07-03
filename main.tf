module "networking" {
  source = "./modules/networking"

  name         = var.cluster_name
  cluster_name = var.cluster_name
  vpc_cidr     = var.vpc_cidr
}

module "eks" {
  source = "./modules/eks"

  cluster_name        = var.cluster_name
  kubernetes_version  = var.kubernetes_version
  vpc_id              = module.networking.vpc_id
  private_subnet_ids  = module.networking.private_subnet_ids
  public_subnet_ids   = module.networking.public_subnet_ids
  node_instance_types = var.node_instance_types
  node_desired_size   = var.node_desired_size
  node_min_size       = var.node_min_size
  node_max_size       = var.node_max_size
}

module "iam" {
  source = "./modules/iam"

  cluster_name      = var.cluster_name
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider_url = module.eks.oidc_provider_url
  namespace         = var.namespace
  sqs_queue_arn     = var.sqs_queue_arn
  kb_s3_bucket_arn  = var.kb_s3_bucket_arn
}
