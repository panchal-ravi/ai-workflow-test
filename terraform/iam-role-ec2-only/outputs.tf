# Output values for downstream consumption per constitution §3.2

output "role_arn" {
  description = "ARN of the IAM role"
  value       = module.iam_role_ec2.arn
}

output "role_name" {
  description = "Name of the IAM role"
  value       = module.iam_role_ec2.name
}

output "instance_profile_arn" {
  description = "ARN of the instance profile for EC2"
  value       = module.iam_role_ec2.instance_profile_arn
}

output "instance_profile_name" {
  description = "Name of the instance profile for EC2"
  value       = module.iam_role_ec2.instance_profile_name
}
