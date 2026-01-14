output "role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.ec2_role.arn
}

output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.ec2_role.name
}

output "role_id" {
  description = "Unique ID of the IAM role"
  value       = aws_iam_role.ec2_role.id
}

output "policy_arn" {
  description = "ARN of the IAM policy"
  value       = aws_iam_policy.ec2_least_privilege.arn
}

output "instance_profile_arn" {
  description = "ARN of the instance profile"
  value       = aws_iam_instance_profile.ec2_profile.arn
}

output "instance_profile_name" {
  description = "Name of the instance profile"
  value       = aws_iam_instance_profile.ec2_profile.name
}
