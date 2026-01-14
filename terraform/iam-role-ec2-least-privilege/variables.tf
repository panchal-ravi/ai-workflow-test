variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "role_name" {
  description = "Name of the IAM role"
  type        = string
  default     = "ec2-least-privilege-role"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.role_name))
    error_message = "Role name must contain only alphanumeric characters, hyphens, and underscores."
  }
}
