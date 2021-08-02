resource "aws_iam_policy" "eks_efs_csi_driver_policy" {
  count       = var.eks_integration ? 1 : 0
  name        = "eksEfsCsiDriverPolicy-${var.name}"
  policy      = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "elasticfilesystem:DescribeAccessPoints",
        "elasticfilesystem:DescribeFileSystems"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "elasticfilesystem:CreateAccessPoint"
      ],
      "Resource": "*",
      "Condition": {
        "StringLike": {
          "aws:RequestTag/efs.csi.aws.com/cluster": "true"
        }
      }
    },
    {
      "Effect": "Allow",
      "Action": "elasticfilesystem:DeleteAccessPoint",
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "aws:ResourceTag/efs.csi.aws.com/cluster": "true"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role" "eks_efs_csi_driver_role" {
  count   = var.eks_integration ? 1 : 0
  name    = "eksEfsCsiDriverRole-${var.name}"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "${var.oidc_provider_arn}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${var.oidc_provider_arn}:sub": "system:serviceaccount:kube-system:efs-csi-controller-sa"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "eks_efs_policy_attachment" {
  count       = var.eks_integration ? 1 : 0
  policy_arn = aws_iam_policy.eks_efs_csi_driver_policy.*.arn[count.index]
  role       = aws_iam_role.eks_efs_csi_driver_role.*.name[count.index]
}
