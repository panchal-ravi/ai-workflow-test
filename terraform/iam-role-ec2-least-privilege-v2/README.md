# IAM Role with Least Privilege EC2 Access

This Terraform module creates an IAM role with least privilege access to EC2 resources following AWS security best practices.

## Overview

The module provisions:
- IAM role with EC2 service as trusted entity
- Inline policy with read-only EC2 permissions (Describe*, Get*, List*)
- No access to other AWS services
- Configurable tags and naming

## Security Features

- **Least Privilege**: Only grants read-only EC2 permissions
- **Specific Actions**: Limited to Describe, Get, and List operations
- **Service-Scoped**: Trust policy only allows EC2 service assumption
- **No Write Access**: Cannot modify, create, or delete EC2 resources

## Usage

```hcl
module "ec2_least_privilege_role" {
  source = "./terraform/iam-role-ec2-least-privilege-v2"
  
  role_name        = "my-ec2-readonly-role"
  role_description = "IAM role with read-only EC2 access"
  aws_region       = "us-east-1"
  
  tags = {
    Environment = "production"
    Owner       = "security-team"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| role_name | Name of the IAM role | string | "ec2-least-privilege-role" | no |
| role_description | Description of the IAM role | string | "IAM role with least privilege access to EC2 resources (read-only)" | no |
| aws_region | AWS region | string | "us-east-1" | no |
| tags | Tags to apply to the IAM role | map(string) | See variables.tf | no |

## Outputs

| Name | Description |
|------|-------------|
| role_arn | ARN of the IAM role |
| role_name | Name of the IAM role |
| role_id | ID of the IAM role |
| role_unique_id | Unique ID of the IAM role |
| policy_name | Name of the IAM role policy |

## Permissions Granted

The role grants the following EC2 permissions:
- `ec2:Describe*` - Describe EC2 resources
- `ec2:Get*` - Get EC2 resource information
- `ec2:List*` - List EC2 resources

## Testing

Testing values are provided in `sandbox.auto.tfvars` for sandbox environment deployment.

```bash
terraform init
terraform plan
terraform apply
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | ~> 5.0 |

## Compliance

This module follows:
- AWS IAM best practices for least privilege
- AWS Well-Architected Framework security pillar
- Principle of least privilege (PoLP)

## Notes

- This role only grants read-only access to EC2 resources
- For write access, additional permissions must be explicitly added
- Role can only be assumed by EC2 service
- All resources are tagged for tracking and compliance
