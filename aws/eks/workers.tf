#
# EKS Worker Nodes Resources
#  * IAM role allowing Kubernetes actions to access other AWS services
#  * EKS Node Group to launch worker nodes
#

resource "aws_iam_role" "workers_iam_role" {
  name = "eksWorkersRole-${var.cluster_name}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

# Workers need this for fetching mount targets for EFS
resource "aws_iam_policy" "workers_efs_policy" {
  name        = "eksWorkersEFSPolicy-${var.cluster_name}"

  policy      = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticfilesystem:DescribeAccessPoints",
        "elasticfilesystem:DescribeFileSystemPolicy",
        "elasticfilesystem:DescribeFileSystems",
        "elasticfilesystem:DescribeBackupPolicy",
        "elasticfilesystem:DescribeLifecycleConfiguration",
        "elasticfilesystem:DescribeMountTargetSecurityGroups",
        "elasticfilesystem:DescribeMountTargets",
        "elasticfilesystem:DescribeTags",
        "ec2:DescribeSubnets",
        "ec2:DescribeNetworkInterfaces",
        "ec2:DescribeNetworkInterfaceAttribute"
      ],
      "Resource": "*"
    }
  ]
}
POLICY
}

# Policy attachment
resource "aws_iam_role_policy_attachment" "attachment_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.workers_iam_role.name
}

resource "aws_iam_role_policy_attachment" "attachment_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.workers_iam_role.name
}

resource "aws_iam_role_policy_attachment" "attachment_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.workers_iam_role.name
}

resource "aws_iam_role_policy_attachment" "attachment_workers_efs_policy" {
  policy_arn = aws_iam_policy.workers_efs_policy.arn
  role       = aws_iam_role.workers_iam_role.name
}

resource "aws_eks_node_group" "node_group" {
  count           = length(var.node_groups)
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = var.node_groups.*.node_group_name[count.index]
  node_role_arn   = aws_iam_role.workers_iam_role.arn
  capacity_type   = var.node_groups.*.capacity_type[count.index]
  subnet_ids      = var.subnet_ids[*]
  instance_types  = var.node_groups.*.instance_types[count.index]
  disk_size       = var.node_groups.*.disk_size[count.index]

  scaling_config {
    desired_size = var.node_groups.*.scaling_config.desired_size[count.index]
    max_size     = var.node_groups.*.scaling_config.max_size[count.index]
    min_size     = var.node_groups.*.scaling_config.min_size[count.index]
  }

  labels = var.node_groups.*.labels[count.index]

  depends_on = [
    kubernetes_config_map.auth_config_map,
    aws_iam_role_policy_attachment.attachment_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.attachment_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.attachment_AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.attachment_workers_efs_policy,
  ]
}