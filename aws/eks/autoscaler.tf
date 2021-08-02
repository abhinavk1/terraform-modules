locals {
  oidc_issuer_url   = aws_eks_cluster.eks_cluster.identity.0.oidc.0.issuer
}

data "tls_certificate" "cluster_issuer" {
  url        = local.oidc_issuer_url
  depends_on = [aws_eks_cluster.eks_cluster]
}

resource "aws_iam_openid_connect_provider" "oidc_provider" {
  url             = local.oidc_issuer_url
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.cluster_issuer.certificates.0.sha1_fingerprint]
  depends_on      = [aws_eks_cluster.eks_cluster]
}

module "iam_assumable_role_admin" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "3.6.0"
  create_role                   = var.enable_autoscaling ? true : false
  role_policy_arns              = var.enable_autoscaling ? [aws_iam_policy.cluster_autoscaler_policy.*.arn[0]] : []
  role_name                     = "cluster-autoscaler-role-${var.cluster_name}"
  provider_url                  = replace(local.oidc_issuer_url, "https://", "")
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:cluster-autoscaler"]

  depends_on = [
    aws_eks_cluster.eks_cluster,
    aws_eks_node_group.node_group,
    aws_iam_openid_connect_provider.oidc_provider,
  ]
}

resource "aws_iam_policy" "cluster_autoscaler_policy" {
  count       = var.enable_autoscaling ? 1 : 0
  name        = "cluster-autoscaler-policy-${var.cluster_name}"
  description = "EKS cluster-autoscaler policy for cluster ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.cluster_autoscaler_policy_document.json
}

data "aws_iam_policy_document" "cluster_autoscaler_policy_document" {

  statement {
    sid    = "clusterAutoscaler"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
      "ec2:DescribeLaunchTemplateVersions",
    ]

    resources = ["*"]
  }
}