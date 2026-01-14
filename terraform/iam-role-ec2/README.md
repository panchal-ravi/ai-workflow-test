# AWS IAM Role with Least Privilege EC2 Access

This Terraform module creates an AWS IAM Role with least privilege access to EC2 resources, following AWS security best practices.

## Features

- **Least Privilege Access**: Role permissions are limited to essential EC2 operations
- **Read-Only Operations**: Full describe, get, and list access to EC2 resources
- **Conditional Write Access**: Instance management (start/stop/reboot) only for tagged resources
- **CloudWatch Integration**: Access to metrics for monitoring
- **External ID Protection**: Additional security layer for role assumption
- **Instance Profile**: Ready-to-use profile for attaching to EC2 instances

## Security Best Practices

1. **Resource Tagging**: Write operations are restricted to instances with specific tags
2. **External ID**: Required for assuming the role, preventing confused deputy attacks
3. **Minimal Permissions**: Only necessary EC2 actions are granted
4. **No Sensitive Data**: No hardcoded credentials or secrets

## Resources Created

- IAM Role with trust policy
- IAM Policy with least privilege permissions
- IAM Policy Attachment
- IAM Instance Profile

## Usage

1. Copy `terraform.tfvars.example` to `terraform.tfvars`:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Update `terraform.tfvars` with your values:
   ```hcl
   aws_region  = "us-east-1"
   role_name   = "ec2-least-privilege-role"
   external_id = "your-secure-external-id"
   
   tags = {
     Environment = "production"
     Project     = "my-project"
   }
   ```

3. Initialize Terraform:
   ```bash
   terraform init
   ```

4. Review the plan:
   ```bash
   terraform plan
   ```

5. Apply the configuration:
   ```bash
   terraform apply
   ```

## Permissions Granted

### Read-Only Access
- `ec2:Describe*` - Describe all EC2 resources
- `ec2:Get*` - Get EC2 resource information
- `ec2:List*` - List EC2 resources

### Conditional Write Access
- `ec2:StartInstances` - Start instances (tagged only)
- `ec2:StopInstances` - Stop instances (tagged only)
- `ec2:RebootInstances` - Reboot instances (tagged only)

**Condition**: Resources must have the tag `ManagedBy` matching the role name.

### Monitoring
- `cloudwatch:GetMetricStatistics` - View CloudWatch metrics
- `cloudwatch:ListMetrics` - List available metrics

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| aws_region | AWS region where resources will be created | `string` | `"us-east-1"` | no |
| role_name | Name of the IAM role | `string` | `"ec2-least-privilege-role"` | no |
| external_id | External ID for additional security | `string` | n/a | yes |
| tags | Additional tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| role_arn | ARN of the IAM role |
| role_name | Name of the IAM role |
| role_id | ID of the IAM role |
| policy_arn | ARN of the IAM policy |
| instance_profile_arn | ARN of the instance profile |
| instance_profile_name | Name of the instance profile |

## Example: Attaching to EC2 Instance

```hcl
resource "aws_instance" "example" {
  ami                  = "ami-12345678"
  instance_type        = "t3.micro"
  iam_instance_profile = module.iam_role.instance_profile_name
  
  tags = {
    ManagedBy = "ec2-least-privilege-role"
  }
}
```

## Requirements

- Terraform >= 1.0
- AWS Provider ~> 5.0
- Valid AWS credentials configured

## Security Notes

1. **External ID**: Generate a unique, random external ID and store it securely
2. **Tag Compliance**: Ensure EC2 instances have the correct `ManagedBy` tag for write operations
3. **Regular Audits**: Review and audit role usage regularly
4. **Credential Rotation**: Rotate external IDs periodically

## License

This code is provided as-is for infrastructure provisioning purposes.
