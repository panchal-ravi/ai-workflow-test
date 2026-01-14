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

# IAM Role for EC2 with least privilege access
resource "aws_iam_role" "ec2_least_privilege" {
  name               = var.role_name
  description        = "IAM Role with least privilege access to EC2 resources"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json

  tags = merge(
    var.tags,
    {
      Name        = var.role_name
      ManagedBy   = "Terraform"
      Purpose     = "EC2 Least Privilege Access"
    }
  )
}

# Trust policy for assuming the role
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    
    actions = ["sts:AssumeRole"]
    
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.external_id]
    }
  }
}

# IAM Policy with least privilege EC2 permissions
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
  
  # Limited instance management (only for tagged instances)
  statement {
    sid    = "EC2InstanceManagement"
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
      values   = ["${var.role_name}"]
    }
  }
  
  # CloudWatch metrics for monitoring
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

resource "aws_iam_role_policy_attachment" "ec2_least_privilege" {
  role       = aws_iam_role.ec2_least_privilege.name
  policy_arn = aws_iam_policy.ec2_least_privilege.arn
}

# Instance profile for attaching role to EC2 instances
resource "aws_iam_instance_profile" "ec2_least_privilege" {
  name = "${var.role_name}-instance-profile"
  role = aws_iam_role.ec2_least_privilege.name

  tags = merge(
    var.tags,
    {
      Name      = "${var.role_name}-instance-profile"
      ManagedBy = "Terraform"
    }
  )
}
