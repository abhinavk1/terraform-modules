terraform {
  required_version = ">= 0.15.0"
}

provider "aws" {
  region = "us-east-2"
}

module "ecr" {
  source = "../../aws/ecr"

  repository_names = [
    "project/repository-name"
  ]
}