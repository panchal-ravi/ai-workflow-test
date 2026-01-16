# Provider configuration per constitution §3.2

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "IAM Role EC2 Only"
      ManagedBy   = "Terraform"
      Environment = var.environment
    }
  }
}
