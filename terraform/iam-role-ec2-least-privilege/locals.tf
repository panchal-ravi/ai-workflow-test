locals {
  common_tags = merge(
    var.tags,
    {
      CreatedBy = "Terraform"
      Module    = "iam-role-ec2-least-privilege"
    }
  )
}
