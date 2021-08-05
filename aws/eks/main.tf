#
# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS services
#  * EC2 Security Group to allow networking traffic with EKS cluster
#  * EKS Cluster
#

resource "aws_iam_role" "cluster_iam_role" {
  name = "eksClusterRole-${var.cluster_name}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_iam_role.name
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.cluster_iam_role.name
}

resource "aws_security_group" "cluster_security_group" {
  name        = "cluster-security-group-${var.cluster_name}"
  description = "Cluster communication with worker nodes"
  vpc_id      = var.vpc_id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cluster-security-group-${var.cluster_name}"
  }
}

resource "aws_security_group_rule" "allow_https_kube_api_access" {
  count             = var.kube_api_public_access ? 1 : 0
  description       = "Allow communication with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.cluster_security_group.id
  to_port           = 443
  type              = "ingress"
  cidr_blocks       = ["0.0.0.0/0"]
}

resource "aws_security_group_rule" "allow_worker_node_discovery" {
  description       = "Allow worker nodes to join to the cluster"
  from_port         = 10250
  protocol          = "tcp"
  security_group_id = aws_security_group.cluster_security_group.id
  to_port           = 10250
  type              = "ingress"
  cidr_blocks       = [var.vpc_cidr_block]
}

resource "aws_security_group_rule" "allow_efs_access" {
  count             = var.allow_efs ? 1 : 0
  description       = "Allow network file system related operations"
  from_port         = 2049
  protocol          = "tcp"
  security_group_id = aws_security_group.cluster_security_group.id
  to_port           = 2049
  type              = "ingress"
  cidr_blocks       = [var.vpc_cidr_block]
}

resource "aws_eks_cluster" "eks_cluster" {
  name      = var.cluster_name
  role_arn  = aws_iam_role.cluster_iam_role.arn
  version   = var.kube_version

  vpc_config {
    security_group_ids      = [aws_security_group.cluster_security_group.id]
    subnet_ids              = var.subnet_ids

    # Allow Kube API to be accessed from within and also outside of the cluster
    endpoint_private_access = true
    endpoint_public_access  = var.kube_api_public_access
  }

  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.cluster_AmazonEKSVPCResourceController,
  ]
}