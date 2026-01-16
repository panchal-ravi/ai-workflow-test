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

output "role_unique_id" {
  description = "Unique ID of the IAM role"
  value       = aws_iam_role.ec2_least_privilege.unique_id
}

output "policy_name" {
  description = "Name of the IAM role policy"
  value       = aws_iam_role_policy.ec2_least_privilege.name
}
