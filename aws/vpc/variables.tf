variable "name" {
  type = string
}

variable "eks_cluster_owned" {
  type    = bool
  default = false
}

variable "eks_cluster_name" {
  type    = string
  default = null
}

variable "s3_region" {
  type    = string
  default = null
}

# VPC
variable cidr_block {
  type    = string
}

# Subnets

variable "availability_zones" {
  type = list(string)
}

variable "public_subnet_cidr_blocks" {
  type    = list(string)
}

variable "private_subnet_cidr_blocks" {
  type    = list(string)
}
