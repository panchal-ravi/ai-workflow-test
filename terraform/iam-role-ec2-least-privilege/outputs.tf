output "role_arn" {
  description = "ARN of the IAM role"
  value       = aws_iam_role.ec2_least_privilege.arn
}

output "role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.ec2_least_privilege.name
}

output "role_id" {
  description = "ID of the IAM role"
  value       = aws_iam_role.ec2_least_privilege.id
}

output "policy_arn" {
  description = "ARN of the IAM policy"
  value       = aws_iam_policy.ec2_least_privilege.arn
}

output "policy_name" {
  description = "Name of the IAM policy"
  value       = aws_iam_policy.ec2_least_privilege.name
}

output "instance_profile_arn" {
  description = "ARN of the instance profile (if created)"
  value       = var.create_instance_profile ? aws_iam_instance_profile.ec2_least_privilege[0].arn : null
}

output "instance_profile_name" {
  description = "Name of the instance profile (if created)"
  value       = var.create_instance_profile ? aws_iam_instance_profile.ec2_least_privilege[0].name : null
}
