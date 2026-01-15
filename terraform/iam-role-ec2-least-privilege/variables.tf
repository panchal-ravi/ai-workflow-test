variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "role_name" {
  description = "Name of the IAM role"
  type        = string
  default     = "ec2-least-privilege-role"

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.role_name))
    error_message = "Role name must contain only alphanumeric characters, hyphens, and underscores"
  }
}

variable "trusted_principals" {
  description = "List of AWS ARNs that can assume this role (in addition to EC2 service)"
  type        = list(string)
  default     = []
}

variable "create_instance_profile" {
  description = "Whether to create an instance profile for EC2 instances"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "production"
    Project     = "infrastructure"
  }
}
