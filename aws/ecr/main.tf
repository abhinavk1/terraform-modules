resource "aws_ecr_repository" "ecr_repository" {
  count = length(var.repository_names)
  name  = var.repository_names[count.index]
}

resource "aws_ecr_lifecycle_policy" "repo_lifecycle_policy" {
  count      = var.lifecycle_policy == null ? 0 : length(var.repository_names)
  repository = var.repository_names[count.index]
  policy     = var.lifecycle_policy
}
