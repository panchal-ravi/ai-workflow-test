# AWS IAM Role with Least Privilege EC2 Access

This Terraform configuration creates an AWS IAM role with least privilege access to EC2 resources, following AWS security best practices.

## Features

- **Least Privilege Principle**: Only grants necessary EC2 permissions
- **Read-Only Access**: Full describe, get, and list capabilities for EC2 resources
- **Conditional Instance Management**: Start/stop/reboot only for instances tagged with `ManagedBy=Terraform`
- **Instance Profile**: Includes IAM instance profile for EC2 attachment
- **Security Best Practices**: Implements AWS Well-Architected Framework recommendations

## Permissions Granted

### Read-Only Access
- `ec2:Describe*` - View all EC2 resources
- `ec2:Get*` - Retrieve EC2 resource details
- `ec2:List*` - List EC2 resources

### Conditional Instance Management
- `ec2:StartInstances` - Start instances (conditional)
- `ec2:StopInstances` - Stop instances (conditional)
- `ec2:RebootInstances` - Reboot instances (conditional)

**Condition**: Operations only allowed on instances with tag `ManagedBy=Terraform`

## Usage

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed

### Deployment

```bash
# Initialize Terraform
terraform init

# Review the execution plan
terraform plan

# Apply the configuration
terraform apply

# Destroy resources when no longer needed
terraform destroy
```

### Custom Configuration

Create a `terraform.tfvars` file to customize variables:

```hcl
aws_region  = "us-west-2"
environment = "production"
role_name   = "my-ec2-role"
```

## Outputs

- `iam_role_arn` - ARN of the created IAM role
- `iam_role_name` - Name of the IAM role
- `iam_policy_arn` - ARN of the IAM policy
- `instance_profile_arn` - ARN of the instance profile
- `instance_profile_name` - Name of the instance profile

## Security Considerations

1. **Least Privilege**: Role only has EC2-specific permissions, no access to other AWS services
2. **Conditional Access**: Instance management actions are restricted to tagged resources
3. **No Wildcard Actions**: Specific actions are whitelisted instead of using wildcards
4. **Resource Restrictions**: Instance management limited to specific region and account
5. **Audit Trail**: All actions are logged in AWS CloudTrail

## Compliance

This configuration follows:
- AWS Well-Architected Framework Security Pillar
- CIS AWS Foundations Benchmark
- Principle of Least Privilege (PoLP)

## Tags

All resources are tagged with:
- `Environment` - Environment designation
- `ManagedBy` - Set to "Terraform"
- `Purpose` - Set to "EC2LeastPrivilegeAccess"
