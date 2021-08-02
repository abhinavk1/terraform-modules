terraform {
  required_version = ">= 0.15.0"
}

provider "aws" {
  region = var.region
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
  enable_autoscaling = true
  manage_aws_auth = true
  map_users = var.map_users
  node_groups = var.node_groups
  subnet_ids = module.vpc.private_subnet_ids # Workers will be in private subnets
  vpc_cidr_block = var.cidr_block
  vpc_id = module.vpc.vpc_id
}

# For authorizing module to add IAM users defined under var.map_users to the AWS auth config map
provider "kubernetes" {
  host                   = module.eks_cluster.host
  cluster_ca_certificate = module.eks_cluster.cluster_ca_certificate
  token                  = module.eks_cluster.token
}
