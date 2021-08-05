terraform {
  required_version = ">= 0.15.0"
}

provider "aws" {
  region = "us-east-2"
}

module "vpc" {
  source = "../../aws/vpc"

  name = "vpc"
  availability_zones = var.availability_zones
  cidr_block = var.cidr_block
  public_subnet_cidr_blocks = var.public_subnet_cidr_blocks
  private_subnet_cidr_blocks = var.private_subnet_cidr_blocks

  eks_cluster_owned = true
  eks_cluster_name = var.eks_cluster_name
}

module "eks_cluster" {
  source = "../../aws/eks"

  cluster_name = var.eks_cluster_name
  kube_version = "1.19"
  enable_autoscaling = false
  node_groups = var.node_groups
  subnet_ids = module.vpc.private_subnet_ids
  vpc_cidr_block = var.cidr_block
  vpc_id = module.vpc.vpc_id
  kube_api_public_access = true
  allow_efs = var.eks_efs_integration
}

module "eks_efs" {
  source = "../../aws/efs"

  name = "efs"
  eks_integration = var.eks_efs_integration
  oidc_provider_arn  = module.eks_cluster.oidc_provider_arn
  security_group_ids = [module.eks_cluster.security_group_id]
  subnet_ids         = module.vpc.private_subnet_ids

  depends_on = [module.vpc, module.eks_cluster]
}
