# IAM Role with EC2-only access
# Uses private registry module per constitution §1.1

module "iam_role_ec2" {
  source  = "app.terraform.io/ravi-panchal-org/iam/aws//modules/iam-role"
  version = "~> 6.2.0"

  name        = var.role_name
  description = "IAM role with EC2-only access for compute workloads"

  # Trust policy allowing EC2 service to assume this role
  trust_policy_permissions = {
    EC2ServiceTrust = {
      actions = ["sts:AssumeRole"]
      principals = [{
        type        = "Service"
        identifiers = ["ec2.amazonaws.com"]
      }]
    }
  }

  # EC2 read-only access policy
  policies = {
    EC2ReadOnly = "arn:aws:iam::aws:policy/AmazonEC2ReadOnlyAccess"
  }

  # Enable instance profile for EC2 instances
  create_instance_profile = true

  tags = local.common_tags
}
