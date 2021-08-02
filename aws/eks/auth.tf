resource "kubernetes_config_map" "auth_config_map" {
  count      = var.manage_aws_auth ? 1 : 0

  metadata {
    name = "aws-auth"
    namespace = "kube-system"

    labels = {
      "app.kubernetes.io/managed-by" = "Terraform"
    }
  }

  data = {
    mapRoles = <<YAML
- rolearn: ${aws_iam_role.workers_iam_role.arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes
YAML

    mapUsers = yamlencode(var.map_users)
  }

  depends_on = [aws_eks_cluster.eks_cluster]
}
