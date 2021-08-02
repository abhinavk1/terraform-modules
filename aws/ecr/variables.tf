variable "repository_names" {
  type = list(string)
}

variable "lifecycle_policy" {
  description = "Manages the ECR repository lifecycle policy"
  type        = string
  default     = null
}
