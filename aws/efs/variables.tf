variable "name" {
  type = string
}

variable "oidc_provider_arn" {
  type    = string
  default = null
}

variable "eks_integration" {
  type    = bool
  default = false
}

variable "performance_mode" {
  type        = string
  description = "The file system performance mode. Can be either generalPurpose or maxIO"
  default     = "generalPurpose"
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}
