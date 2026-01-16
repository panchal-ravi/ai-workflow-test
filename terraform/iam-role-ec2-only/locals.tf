# Local values for resource configuration

locals {
  common_tags = merge(
    var.tags,
    {
      ManagedBy   = "Terraform"
      Environment = var.environment
      Purpose     = "EC2 service role"
    }
  )
}
