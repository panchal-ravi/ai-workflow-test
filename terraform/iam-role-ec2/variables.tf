variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "role_name" {
  description = "Name of the IAM role"
  type        = string
  default     = "ec2-least-privilege-role"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9+=,.@_-]+$", var.role_name))
    error_message = "Role name must contain only alphanumeric characters and +=,.@_-"
  }
}

variable "external_id" {
  description = "External ID for additional security when assuming the role"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.external_id) >= 8
    error_message = "External ID must be at least 8 characters long"
  }
}

variable "tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
}
