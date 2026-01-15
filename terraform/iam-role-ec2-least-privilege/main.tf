terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# IAM role with least privilege access to EC2
resource "aws_iam_role" "ec2_least_privilege" {
  name               = var.role_name
  description        = "IAM role with least privilege access to EC2 resources"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = merge(
    var.tags,
    {
      ManagedBy = "Terraform"
      Purpose   = "EC2 Least Privilege Access"
    }
  )
}

# Trust policy - who can assume this role
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }

  # Optional: Allow specific AWS accounts or users to assume this role
  dynamic "statement" {
    for_each = length(var.trusted_principals) > 0 ? [1] : []
    content {
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = var.trusted_principals
      }
      actions = ["sts:AssumeRole"]
    }
  }
}

# Least privilege EC2 policy
resource "aws_iam_policy" "ec2_least_privilege" {
  name        = "${var.role_name}-policy"
  description = "Least privilege policy for EC2 operations"
  policy      = data.aws_iam_policy_document.ec2_least_privilege.json

  tags = var.tags
}

# Policy document with least privilege EC2 permissions
data "aws_iam_policy_document" "ec2_least_privilege" {
  # Read-only EC2 permissions
  statement {
    sid    = "EC2ReadOnly"
    effect = "Allow"
    actions = [
      "ec2:Describe*",
      "ec2:Get*",
      "ec2:List*"
    ]
    resources = ["*"]
  }

  # Instance management with conditions
  statement {
    sid    = "EC2InstanceManagement"
    effect = "Allow"
    actions = [
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:RebootInstances",
      "ec2:TerminateInstances"
    ]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/ManagedBy"
      values   = ["Terraform"]
    }
  }

  # Security group management (limited)
  statement {
    sid    = "SecurityGroupManagement"
    effect = "Allow"
    actions = [
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:RevokeSecurityGroupEgress"
    ]
    resources = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group/*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/ManagedBy"
      values   = ["Terraform"]
    }
  }

  # Volume management
  statement {
    sid    = "EC2VolumeManagement"
    effect = "Allow"
    actions = [
      "ec2:CreateVolume",
      "ec2:DeleteVolume",
      "ec2:AttachVolume",
      "ec2:DetachVolume"
    ]
    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:volume/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/ManagedBy"
      values   = ["Terraform"]
    }
  }

  # Snapshot management
  statement {
    sid    = "EC2SnapshotManagement"
    effect = "Allow"
    actions = [
      "ec2:CreateSnapshot",
      "ec2:DeleteSnapshot",
      "ec2:CopySnapshot"
    ]
    resources = [
      "arn:aws:ec2:${var.aws_region}::snapshot/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:volume/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/ManagedBy"
      values   = ["Terraform"]
    }
  }

  # Tagging - only for resources managed by Terraform
  statement {
    sid    = "EC2Tagging"
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags"
    ]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/ManagedBy"
      values   = ["Terraform"]
    }
  }
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "ec2_least_privilege" {
  role       = aws_iam_role.ec2_least_privilege.name
  policy_arn = aws_iam_policy.ec2_least_privilege.arn
}

# Optional: Instance profile for EC2 instances to use this role
resource "aws_iam_instance_profile" "ec2_least_privilege" {
  count = var.create_instance_profile ? 1 : 0
  name  = "${var.role_name}-instance-profile"
  role  = aws_iam_role.ec2_least_privilege.name

  tags = var.tags
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
