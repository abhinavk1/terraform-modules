data "aws_eks_cluster" "cluster_data" {
  name = aws_eks_cluster.eks_cluster.name
}

data "aws_eks_cluster_auth" "cluster_auth" {
  name = aws_eks_cluster.eks_cluster.name
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.oidc_provider.arn
}

output "security_group_id" {
  value = aws_security_group.cluster_security_group.id
}

output "host" {
  value = data.aws_eks_cluster.cluster_data.endpoint
}

output "cluster_ca_certificate" {
  value = base64decode(data.aws_eks_cluster.cluster_data.certificate_authority.0.data)
}

output "token" {
  value = data.aws_eks_cluster_auth.cluster_auth.token
}