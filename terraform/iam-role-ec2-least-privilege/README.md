# IAM Role with Least Privilege EC2 Access

This Terraform module creates an AWS IAM role with least privilege access to EC2 resources, following AWS security best practices.

## Features

- **Read-Only Access by Default**: Provides describe permissions for EC2 resources
- **Optional Instance Management**: Enable start/stop/reboot with explicit resource ARNs
- **Optional Tag Management**: Enable tag creation/deletion with explicit resource ARNs
- **Instance Profile Support**: Optionally create an instance profile for EC2 instances
- **Security Best Practices**: Follows least privilege principle with resource-level permissions

## Usage

### Basic Read-Only Access

```hcl
module "ec2_role" {
  source = "./terraform/iam-role-ec2-least-privilege"

  role_name        = "ec2-readonly-role"
  role_description = "IAM role with read-only access to EC2"
  
  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

### With Instance Management

```hcl
module "ec2_role" {
  source = "./terraform/iam-role-ec2-least-privilege"

  role_name                  = "ec2-management-role"
  enable_instance_management = true
  
  ec2_resource_arns = [
    "arn:aws:ec2:us-east-1:123456789012:instance/i-1234567890abcdef0",
    "arn:aws:ec2:us-east-1:123456789012:instance/i-0987654321fedcba0"
  ]
  
  tags = {
    Environment = "production"
  }
}
```

### Full Permissions Example

```hcl
module "ec2_role" {
  source = "./terraform/iam-role-ec2-least-privilege"

  role_name                  = "ec2-full-management-role"
  enable_instance_management = true
  enable_tag_management      = true
  create_instance_profile    = true
  
  ec2_resource_arns = [
    "arn:aws:ec2:us-east-1:123456789012:instance/*"
  ]
  
  tags = {
    Environment = "production"
    Team        = "devops"
  }
}
```

## Permissions

### Default Read-Only Permissions

- `ec2:DescribeInstances`
- `ec2:DescribeInstanceStatus`
- `ec2:DescribeTags`
- `ec2:DescribeVolumes`
- `ec2:DescribeSecurityGroups`
- `ec2:DescribeSubnets`
- `ec2:DescribeVpcs`

### Optional Instance Management

When `enable_instance_management = true`:
- `ec2:StartInstances`
- `ec2:StopInstances`
- `ec2:RebootInstances`

### Optional Tag Management

When `enable_tag_management = true`:
- `ec2:CreateTags`
- `ec2:DeleteTags`

## Security Considerations

1. **Least Privilege**: Only read-only access is enabled by default
2. **Resource-Level Permissions**: Management actions require explicit resource ARNs
3. **No Wildcard Permissions**: Avoid using `*` in resource ARNs where possible
4. **Assume Role Policy**: Configured for EC2 service principal only

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| aws | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| role_name | Name of the IAM role | `string` | n/a | yes |
| role_description | Description of the IAM role | `string` | `"IAM role with least privilege access to EC2 resources"` | no |
| enable_instance_management | Enable EC2 instance start/stop/reboot permissions | `bool` | `false` | no |
| enable_tag_management | Enable EC2 tag creation and deletion permissions | `bool` | `false` | no |
| ec2_resource_arns | List of EC2 resource ARNs to apply permissions to | `list(string)` | `[]` | no |
| create_instance_profile | Create an instance profile for EC2 instances | `bool` | `true` | no |
| tags | Tags to apply to IAM resources | `map(string)` | `{}` | no |
| aws_region | AWS region for provider configuration | `string` | `"us-east-1"` | no |
| environment | Environment name for default tags | `string` | `"dev"` | no |

## Outputs

| Name | Description |
|------|-------------|
| role_arn | ARN of the IAM role |
| role_name | Name of the IAM role |
| role_id | ID of the IAM role |
| policy_arn | ARN of the IAM policy |
| policy_id | ID of the IAM policy |
| instance_profile_arn | ARN of the instance profile (if created) |
| instance_profile_name | Name of the instance profile (if created) |

## Testing

The module includes `sandbox.auto.tfvars` for testing:

```bash
cd terraform/iam-role-ec2-least-privilege
terraform init
terraform plan
terraform apply
```

## Best Practices

1. **Start with Read-Only**: Begin with default read-only permissions
2. **Explicit ARNs**: Always specify explicit resource ARNs for management actions
3. **Regular Audits**: Review and audit IAM policies regularly
4. **Tagging**: Use consistent tagging for cost allocation and governance
5. **Documentation**: Document why specific permissions are needed

## License

This module is provided as-is for infrastructure provisioning.
