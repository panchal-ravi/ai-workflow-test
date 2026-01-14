# IAM Role with Least Privilege Access to EC2 Resources
# This configuration creates an IAM role with minimal permissions for EC2 operations

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

# IAM Role for EC2 with least privilege
resource "aws_iam_role" "ec2_least_privilege" {
  name               = var.role_name
  description        = "IAM role with least privilege access to EC2 resources"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  tags = merge(
    var.tags,
    {
      Name        = var.role_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# Trust policy - allows EC2 service to assume this role
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# Least privilege policy for EC2 - read-only and basic instance operations
data "aws_iam_policy_document" "ec2_least_privilege" {
  # Allow read-only EC2 operations
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

  # Allow specific EC2 operations on tagged resources only
  statement {
    sid    = "EC2InstanceOperations"
    effect = "Allow"
    actions = [
      "ec2:StartInstances",
      "ec2:StopInstances",
      "ec2:RebootInstances"
    ]
    resources = ["*"]
    condition {
      test     = "StringEquals"
      variable = "ec2:ResourceTag/ManagedBy"
      values   = ["Terraform"]
    }
  }

  # Allow CloudWatch metrics for EC2 monitoring
  statement {
    sid    = "CloudWatchMetrics"
    effect = "Allow"
    actions = [
      "cloudwatch:GetMetricStatistics",
      "cloudwatch:ListMetrics"
    ]
    resources = ["*"]
  }
}

# Create and attach the least privilege policy
resource "aws_iam_policy" "ec2_least_privilege" {
  name        = "${var.role_name}-policy"
  description = "Least privilege policy for EC2 operations"
  policy      = data.aws_iam_policy_document.ec2_least_privilege.json

  tags = merge(
    var.tags,
    {
      Name        = "${var.role_name}-policy"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

# Attach the policy to the role
resource "aws_iam_role_policy_attachment" "ec2_least_privilege" {
  role       = aws_iam_role.ec2_least_privilege.name
  policy_arn = aws_iam_policy.ec2_least_privilege.arn
}

# Instance profile for attaching the role to EC2 instances
resource "aws_iam_instance_profile" "ec2_least_privilege" {
  name = "${var.role_name}-instance-profile"
  role = aws_iam_role.ec2_least_privilege.name

  tags = merge(
    var.tags,
    {
      Name        = "${var.role_name}-instance-profile"
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}
