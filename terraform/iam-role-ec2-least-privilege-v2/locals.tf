# Locals for computed values
locals {
  role_full_name = "${var.role_name}-${var.aws_region}"
  
  common_tags = merge(
    var.tags,
    {
      CreatedBy = "Terraform"
      Module    = "iam-role-ec2-least-privilege"
    }
  )
}
