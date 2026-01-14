# AWS IAM Role - EC2 Least Privilege Access

This Terraform configuration creates an AWS IAM role with least privilege access to EC2 resources.

## Features

- **Least Privilege Access**: Only grants necessary EC2 permissions
- **Read-Only Operations**: Full describe, get, and list capabilities for EC2 resources
- **Limited Write Operations**: Restricted to starting, stopping, and rebooting instances
- **Tag Management**: Ability to manage tags on EC2 instances and volumes
- **Instance Profile**: Includes an IAM instance profile for EC2 attachment
- **Regional Restrictions**: Permissions are scoped to the specified AWS region

## Permissions Included

### Read-Only Permissions
- `ec2:Describe*` - Describe all EC2 resources
- `ec2:Get*` - Get information about EC2 resources
- `ec2:List*` - List EC2 resources

### Instance Management
- `ec2:StartInstances` - Start EC2 instances
- `ec2:StopInstances` - Stop EC2 instances
- `ec2:RebootInstances` - Reboot EC2 instances

### Tag Management
- `ec2:CreateTags` - Create tags on instances and volumes
- `ec2:DeleteTags` - Delete tags from instances and volumes

## Usage

### Prerequisites
- Terraform >= 1.0
- AWS credentials configured
- Appropriate AWS permissions to create IAM resources

### Deployment

1. **Initialize Terraform**
   ```bash
   terraform init
   ```

2. **Review the Plan**
   ```bash
   terraform plan
   ```

3. **Apply Configuration**
   ```bash
   terraform apply
   ```

### Configuration

Copy the example variables file and customize:
```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` with your desired values:
- `aws_region`: Target AWS region
- `role_name`: Name for the IAM role
- `tags`: Additional resource tags

## Outputs

After deployment, the following outputs are available:

- `role_arn`: ARN of the IAM role
- `role_name`: Name of the IAM role
- `role_id`: Unique ID of the IAM role
- `policy_arn`: ARN of the IAM policy
- `instance_profile_arn`: ARN of the instance profile
- `instance_profile_name`: Name of the instance profile

## Security Considerations

- Permissions are scoped to the specified AWS region
- No permissions for creating, terminating, or modifying EC2 instances
- No access to sensitive operations like key pair management
- Trust relationship limited to EC2 service principal only

## Cleanup

To remove all resources:
```bash
terraform destroy
```

## License

This code is provided as-is for infrastructure provisioning purposes.
