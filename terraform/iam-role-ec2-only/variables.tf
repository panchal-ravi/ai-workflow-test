# Input variables per constitution §3.4

variable "role_name" {
  description = "Name of the IAM role for EC2 access"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.role_name))
    error_message = "Role name must contain only alphanumeric characters, hyphens, and underscores."
  }
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "aws_region" {
  description = "AWS region for provider configuration"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.aws_region))
    error_message = "AWS region must be a valid region format (e.g., us-east-1)."
  }
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
