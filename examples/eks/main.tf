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
  subnet_ids = module.vpc.public_subnet_ids # Workers will be in public subnets
  vpc_cidr_block = var.cidr_block
  vpc_id = module.vpc.vpc_id
  kube_api_public_access = true
}