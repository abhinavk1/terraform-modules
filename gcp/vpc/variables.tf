variable "name" {
  type = string
}

variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "public_subnet_cidr_blocks" {
  type    = list(string)
}

variable "private_subnet_cidr_blocks" {
  type    = list(string)
}
