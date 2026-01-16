variable "role_name" {
  description = "Name of the IAM role"
  type        = string

  validation {
    condition     = length(var.role_name) > 0 && length(var.role_name) <= 64
    error_message = "Role name must be between 1 and 64 characters"
  }
}

variable "role_description" {
  description = "Description of the IAM role"
  type        = string
  default     = "IAM role with least privilege access to EC2 resources"
}

variable "enable_instance_management" {
  description = "Enable EC2 instance start/stop/reboot permissions"
  type        = bool
  default     = false
}

variable "enable_tag_management" {
  description = "Enable EC2 tag creation and deletion permissions"
  type        = bool
  default     = false
}

variable "ec2_resource_arns" {
  description = "List of EC2 resource ARNs to apply permissions to (required if instance or tag management is enabled)"
  type        = list(string)
  default     = []

  validation {
    condition = alltrue([
      for arn in var.ec2_resource_arns :
      can(regex("^arn:aws:ec2:[a-z0-9-]+:[0-9]{12}:(instance|volume)/.*$", arn))
    ])
    error_message = "All ARNs must be valid EC2 instance or volume ARNs"
  }
}

variable "create_instance_profile" {
  description = "Create an instance profile for EC2 instances to assume this role"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Tags to apply to IAM resources"
  type        = map(string)
  default     = {}
}

variable "aws_region" {
  description = "AWS region for provider configuration"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name for default tags"
  type        = string
  default     = "dev"
}
