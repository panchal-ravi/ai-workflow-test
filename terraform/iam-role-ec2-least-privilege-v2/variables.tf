variable "role_name" {
  description = "Name of the IAM role"
  type        = string
  default     = "ec2-least-privilege-role"
  
  validation {
    condition     = length(var.role_name) > 0 && length(var.role_name) <= 64
    error_message = "Role name must be between 1 and 64 characters."
  }
}

variable "role_description" {
  description = "Description of the IAM role"
  type        = string
  default     = "IAM role with least privilege access to EC2 resources (read-only)"
}

variable "tags" {
  description = "Tags to apply to the IAM role"
  type        = map(string)
  default = {
    ManagedBy   = "Terraform"
    Environment = "sandbox"
    Purpose     = "EC2LeastPrivilege"
  }
}
