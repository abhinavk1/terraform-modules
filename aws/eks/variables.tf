# VPC
variable "vpc_id" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "kube_version" {
  type    = string
}

variable "cluster_name" {
  type = string
}

variable "manage_aws_auth" {
  type    = bool
  default = false
}

variable "map_users" {
  description = "Additional IAM users to add to the aws-auth configmap."

  type = list(
  object({
    userarn  = string
    username = string
    groups   = list(string)
  })
  )

  default = []
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

      labels = map
    })
  )
}

variable "enable_autoscaling" {
  type = bool
}
