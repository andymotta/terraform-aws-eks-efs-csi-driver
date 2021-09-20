locals {
  k8s_ecd_service_account_namespace = "kube-system"
  k8s_ecd_service_account_name      = "efs-csi-driver"
}

data "aws_iam_policy_document" "efs_csi_driver" {
  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]

    actions = [
      "elasticfilesystem:DescribeAccessPoints",
      "elasticfilesystem:DescribeFileSystems",
    ]
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]
    actions   = ["elasticfilesystem:CreateAccessPoint"]

    condition {
      test     = "StringLike"
      variable = "aws:RequestTag/efs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }

  statement {
    sid       = ""
    effect    = "Allow"
    resources = ["*"]
    actions   = ["elasticfilesystem:DeleteAccessPoint"]

    condition {
      test     = "StringEquals"
      variable = "aws:ResourceTag/efs.csi.aws.com/cluster"
      values   = ["true"]
    }
  }
}

module "iam_assumable_role_ecd" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "3.6.0"
  create_role                   = true
  role_name                     = "efs-csi-driver"
  provider_url                  = replace(var.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.efs_csi_driver.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:${local.k8s_ecd_service_account_namespace}:${local.k8s_ecd_service_account_name}"]
}

resource "aws_iam_policy" "efs_csi_driver" {
  name_prefix = "efs-csi-driver"
  description = "EKS efs-csi-driver policy for cluster ${var.cluster_name}"
  policy      = data.aws_iam_policy_document.efs_csi_driver.json
}


resource "helm_release" "efs_csi_driver" {
  name       = "efs-csi-driver"
  repository = "https://kubernetes-sigs.github.io/aws-efs-csi-driver"
  chart      = "aws-efs-csi-driver"
  namespace  = "kube-system"
  values = [
    templatefile("${path.module}/efs-csi-driver-values.yaml", {
      efs_csi_driver_role = module.iam_assumable_role_ecd.this_iam_role_arn
      efs_csi_driver_service_account = local.k8s_ecd_service_account_name
    })
  ]
}

resource "aws_efs_file_system" "eks" {
  tags = {
    Name = var.cluster_name
  }
}

resource "aws_security_group" "efs_eks_workers" {
  name        = "efs_eks_workers"
  description = "Allow EFS ingress to EKS worker nodes"
  vpc_id      = var.vpc_id
  ingress {
      description      = "EFS from VPC"
      from_port        = 2049	
      to_port          = 2049
      protocol         = "tcp"
      security_groups      = [var.worker_security_group_id]
  }
  tags = {
    Name = "efs_eks_workers"
  }
}

resource "aws_efs_mount_target" "eks_private" { # rename to workers
  count = length(var.vpc_private_subnets)
  file_system_id = aws_efs_file_system.eks.id
  subnet_id = var.vpc_private_subnets[count.index]
  security_groups = [aws_security_group.efs_eks_workers.id]
}

resource "kubernetes_storage_class" "efs" {
  metadata {
    name = "efs-sc"
  }
  storage_provisioner = "efs.csi.aws.com"
  parameters = {
    provisioningMode = "efs-ap"
    fileSystemId = aws_efs_file_system.eks.id
    directoryPerms = "700"
  }
}