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

# IAM role with EC2 trust relationship
resource "aws_iam_role" "ec2_role" {
  name               = var.role_name
  description        = "IAM role with least privilege access to EC2 resources"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = merge(
    var.tags,
    {
      Name        = var.role_name
      ManagedBy   = "Terraform"
      Purpose     = "EC2LeastPrivilege"
    }
  )
}

# Trust relationship policy for EC2 service
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# IAM policy with least privilege EC2 permissions
resource "aws_iam_policy" "ec2_least_privilege" {
  name        = "${var.role_name}-policy"
  description = "Least privilege policy for EC2 operations"
  policy      = data.aws_iam_policy_document.ec2_least_privilege.json

  tags = merge(
    var.tags,
    {
      Name      = "${var.role_name}-policy"
      ManagedBy = "Terraform"
    }
  )
}

# EC2 least privilege policy document
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

  # Instance management permissions (restricted)
  statement {
    sid    = "EC2InstanceManagement"
    effect = "Allow"
    actions = [
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:RebootInstances"
    ]
    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"
    ]
    condition {
      test     = "StringEquals"
      variable = "aws:RequestedRegion"
      values   = [var.aws_region]
    }
  }

  # Tag management for EC2 resources
  statement {
    sid    = "EC2TagManagement"
    effect = "Allow"
    actions = [
      "ec2:CreateTags",
      "ec2:DeleteTags"
    ]
    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*",
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:volume/*"
    ]
  }
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.ec2_least_privilege.arn
}

# Instance profile for EC2 instances
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.role_name}-profile"
  role = aws_iam_role.ec2_role.name

  tags = merge(
    var.tags,
    {
      Name      = "${var.role_name}-profile"
      ManagedBy = "Terraform"
    }
  )
}

# Data source for current AWS account
data "aws_caller_identity" "current" {}
