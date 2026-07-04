terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Reads stage 1's local state file directly — no shared backend required.
# If stage 1 moves to a remote backend later, update this block to match.
data "terraform_remote_state" "stage1" {
  backend = "local"
  config = {
    path = "${path.module}/../terraform.tfstate"
  }
}

data "aws_eks_cluster_auth" "this" {
  name = data.terraform_remote_state.stage1.outputs.cluster_name
}

provider "kubernetes" {
  host                   = data.terraform_remote_state.stage1.outputs.cluster_endpoint
  cluster_ca_certificate = base64decode(data.terraform_remote_state.stage1.outputs.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = data.terraform_remote_state.stage1.outputs.cluster_endpoint
    cluster_ca_certificate = base64decode(data.terraform_remote_state.stage1.outputs.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}
