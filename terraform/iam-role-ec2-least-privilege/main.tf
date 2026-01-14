# AWS IAM Role with Least Privilege EC2 Access
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

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Purpose     = "EC2LeastPrivilegeAccess"
    }
  }
}

# IAM Role for EC2 with least privilege access
resource "aws_iam_role" "ec2_least_privilege" {
  name        = var.role_name
  description = "IAM role with least privilege access to EC2 resources"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = var.role_name
  }
}

# IAM Policy with least privilege EC2 permissions
resource "aws_iam_policy" "ec2_least_privilege_policy" {
  name        = "${var.role_name}-policy"
  description = "Least privilege policy for EC2 operations - read-only and instance management"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2ReadOnlyAccess"
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "ec2:Get*",
          "ec2:List*"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2InstanceManagement"
        Effect = "Allow"
        Action = [
          "ec2:StartInstances",
          "ec2:StopInstances",
          "ec2:RebootInstances"
        ]
        Resource = "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"
        Condition = {
          StringEquals = {
            "aws:ResourceTag/ManagedBy" = "Terraform"
          }
        }
      }
    ]
  })

  tags = {
    Name = "${var.role_name}-policy"
  }
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "ec2_policy_attachment" {
  role       = aws_iam_role.ec2_least_privilege.name
  policy_arn = aws_iam_policy.ec2_least_privilege_policy.arn
}

# Instance profile for EC2 instances
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.role_name}-instance-profile"
  role = aws_iam_role.ec2_least_privilege.name

  tags = {
    Name = "${var.role_name}-instance-profile"
  }
}

# Data source to get current AWS account ID
data "aws_caller_identity" "current" {}
