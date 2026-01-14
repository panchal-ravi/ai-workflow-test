# AWS IAM Role with Least Privilege EC2 Access

This Terraform configuration creates an AWS IAM role with least privilege access to EC2 resources, following AWS security best practices.

## Features

- **Least Privilege Design**: Grants only the minimum permissions required for EC2 operations
- **Read-Only Access**: Includes EC2 describe, get, and list operations
- **Conditional Operations**: Instance start/stop/reboot limited to resources tagged with `ManagedBy=Terraform`
- **CloudWatch Integration**: Basic CloudWatch metrics access for EC2 monitoring
- **EC2 Trust Policy**: Allows EC2 service to assume the role
- **Instance Profile**: Includes instance profile for attaching role to EC2 instances

## Resources Created

1. **IAM Role** (`aws_iam_role.ec2_least_privilege`)
   - Trust policy allowing EC2 service assumption
   - Tagged with environment and management information

2. **IAM Policy** (`aws_iam_policy.ec2_least_privilege`)
   - Read-only EC2 permissions (Describe*, Get*, List*)
   - Conditional write permissions (Start/Stop/Reboot) on tagged resources
   - CloudWatch metrics access

3. **IAM Role Policy Attachment** (`aws_iam_role_policy_attachment.ec2_least_privilege`)
   - Attaches the policy to the role

4. **IAM Instance Profile** (`aws_iam_instance_profile.ec2_least_privilege`)
   - Enables role attachment to EC2 instances

## Permissions Granted

### Read-Only Permissions
- `ec2:Describe*` - Describe EC2 resources
- `ec2:Get*` - Get EC2 resource information
- `ec2:List*` - List EC2 resources

### Conditional Write Permissions
- `ec2:StartInstances` - Start EC2 instances (only on tagged resources)
- `ec2:StopInstances` - Stop EC2 instances (only on tagged resources)
- `ec2:RebootInstances` - Reboot EC2 instances (only on tagged resources)

**Condition**: Resources must have tag `ManagedBy=Terraform`

### Monitoring Permissions
- `cloudwatch:GetMetricStatistics` - Retrieve CloudWatch metrics
- `cloudwatch:ListMetrics` - List available metrics

## Usage

### Prerequisites
- AWS CLI configured with appropriate credentials
- Terraform >= 1.0 installed
- AWS provider ~> 5.0

### Basic Deployment

```bash
# Initialize Terraform
terraform init

# Review the execution plan
terraform plan

# Apply the configuration
terraform apply
```

### Custom Configuration

Create a `terraform.tfvars` file:

```hcl
aws_region  = "us-west-2"
role_name   = "my-ec2-role"
environment = "prod"

tags = {
  Project = "MyProject"
  Owner   = "DevOps Team"
}
```

### Using the Role with EC2 Instances

```hcl
resource "aws_instance" "example" {
  ami                  = "ami-xxxxx"
  instance_type        = "t3.micro"
  iam_instance_profile = module.iam_role.instance_profile_name

  tags = {
    ManagedBy = "Terraform"  # Required for start/stop/reboot permissions
  }
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| aws_region | AWS region where resources will be created | string | us-east-1 | no |
| role_name | Name of the IAM role | string | ec2-least-privilege-role | no |
| environment | Environment name (dev, staging, prod) | string | dev | no |
| tags | Additional tags to apply to resources | map(string) | {} | no |

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

## Security Best Practices

1. **Least Privilege**: Only grants minimum required permissions
2. **Resource Tagging**: Write operations limited to tagged resources
3. **Service-Specific Trust**: Only EC2 service can assume the role
4. **No Wildcard Actions**: Specific action patterns used where possible
5. **Read-Heavy Design**: Most permissions are read-only

## Testing

Validate the configuration:

```bash
# Format code
terraform fmt

# Validate syntax
terraform validate

# Security scan (requires tfsec)
tfsec .
```

## Cleanup

To remove all created resources:

```bash
terraform destroy
```

## Notes

- This role is designed for EC2 instances that need basic self-management capabilities
- Write operations (start/stop/reboot) require the `ManagedBy=Terraform` tag
- Consider adding additional restrictions based on your specific use case
- Review and audit permissions regularly

## License

This configuration is provided as-is for educational and operational purposes.
