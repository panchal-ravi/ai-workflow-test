provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project   = "IAM-EC2-LeastPrivilege"
      ManagedBy = "Terraform"
    }
  }
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}
