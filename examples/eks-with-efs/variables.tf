variable "availability_zones" {
  type = list(string)
  default = ["us-east-2a", "us-east-2b"]
}

variable cidr_block {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr_blocks" {
  type    = list(string)
  default = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidr_blocks" {
  type    = list(string)
  default = ["10.0.2.0/24", "10.0.3.0/24"]
}

variable "eks_cluster_name" {
  type = string
  default = "eks-cluster"
}

variable "eks_efs_integration" {
  type    = bool
  default = true
}

variable "node_groups" {
  type = list(
  object({
    node_group_name = string
    capacity_type   = string  # Can be either ON_DEMAND or SPOT
    instance_types  = list(string)
    disk_size       = number

    scaling_config = object({
      desired_size = number
      max_size     = number
      min_size     = number
    })

    labels = map(string)
  })
  )

  default = [
    {
      node_group_name = "eks-node-group-on-demand"
      capacity_type   = "ON_DEMAND"
      instance_types  = ["t3.large"]
      disk_size       = 20

      scaling_config = {
        desired_size = 2
        max_size     = 2
        min_size     = 2
      }

      labels = {}
    }
  ]
}