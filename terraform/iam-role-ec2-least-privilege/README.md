# AWS IAM Role - Least Privilege EC2 Access

This Terraform module creates an AWS IAM role with least privilege access to EC2 resources following AWS security best practices.

## Features

- **Least Privilege Design**: Permissions are scoped to only necessary EC2 operations
- **Resource Tagging Conditions**: Actions are restricted to resources tagged with `ManagedBy=Terraform`
- **Read-Only Access**: Comprehensive describe, get, and list permissions for visibility
- **Controlled Management**: Limited write permissions for instance lifecycle, volumes, snapshots, and security groups
- **Instance Profile**: Optional EC2 instance profile creation for attaching the role to instances
- **Flexible Trust Policy**: Supports EC2 service and additional trusted principals

## Security Best Practices Implemented

1. **Condition-Based Access**: All destructive operations require specific resource tags
2. **Regional Scoping**: Permissions are scoped to specified AWS region
3. **Account Isolation**: Resource ARNs include account ID to prevent cross-account access
4. **Minimal Permissions**: Only essential EC2 operations are granted
5. **No Wildcard Actions**: Each action is explicitly defined

## Permissions Granted

### Read-Only
- All EC2 Describe, Get, and List operations

### Instance Management
- Start, Stop, Reboot, Terminate instances (with ManagedBy=Terraform tag condition)

### Security Group Management
- Authorize/Revoke ingress and egress rules (with tag condition)

### Volume Management
- Create, Delete, Attach, Detach volumes (with tag condition)

### Snapshot Management
- Create, Delete, Copy snapshots (with tag condition)

### Tagging
- Create and Delete tags (with tag condition)

## Usage

```hcl
module "ec2_least_privilege_role" {
  source = "./terraform/iam-role-ec2-least-privilege"

  role_name              = "my-ec2-role"
  aws_region             = "us-west-2"
  create_instance_profile = true
  
  trusted_principals = [
    "arn:aws:iam::123456789012:user/admin"
  ]

  tags = {
    Environment = "production"
    Project     = "web-app"
    ManagedBy   = "Terraform"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| aws_region | AWS region for resources | string | "us-east-1" | no |
| role_name | Name of the IAM role | string | "ec2-least-privilege-role" | no |
| trusted_principals | List of AWS ARNs that can assume this role | list(string) | [] | no |
| create_instance_profile | Whether to create an instance profile | bool | true | no |
| tags | Tags to apply to all resources | map(string) | See variables.tf | no |

## Outputs

| Name | Description |
|------|-------------|
| role_arn | ARN of the IAM role |
| role_name | Name of the IAM role |
| role_id | ID of the IAM role |
| policy_arn | ARN of the IAM policy |
| policy_name | Name of the IAM policy |
| instance_profile_arn | ARN of the instance profile |
| instance_profile_name | Name of the instance profile |

## Deployment

1. Initialize Terraform:
```bash
cd terraform/iam-role-ec2-least-privilege
terraform init
```

2. Review the plan:
```bash
terraform plan
```

3. Apply the configuration:
```bash
terraform apply
```

## Important Notes

- **Resource Tagging**: For this role to manage EC2 resources, they must be tagged with `ManagedBy=Terraform`
- **Regional Scope**: Permissions are restricted to the specified AWS region
- **Instance Profile**: If `create_instance_profile` is true, you can attach the profile to EC2 instances
- **Custom Principals**: Use `trusted_principals` to allow specific users or roles to assume this role

## Security Considerations

- This role enforces least privilege by requiring specific tags on resources
- All write operations are conditional on resource tags
- Read-only operations have no conditions for operational visibility
- Review and adjust permissions based on your specific use case
- Consider implementing additional SCP (Service Control Policies) at the organization level

## License

This module follows organizational Terraform standards and security policies.
