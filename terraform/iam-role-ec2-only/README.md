# IAM Role with EC2-Only Access

This Terraform configuration creates an IAM role that provides EC2-only access using the organization's private module registry.

## Features

- IAM role with EC2 service trust policy
- EC2 read-only access policy attached
- Instance profile for EC2 instances
- Environment-specific tagging

## Requirements

- Terraform >= 1.6.0
- AWS Provider ~> 5.0
- Access to `ravi-panchal-org` private module registry

## Usage

```hcl
module "iam_role_ec2" {
  source = "./terraform/iam-role-ec2-only"

  role_name   = "ec2-compute-role"
  environment = "dev"
  aws_region  = "us-east-1"

  tags = {
    Owner       = "platform-team"
    CostCenter  = "engineering"
  }
}
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| role_name | Name of the IAM role | string | yes |
| environment | Deployment environment (dev/staging/prod) | string | yes |
| aws_region | AWS region for provider | string | yes |
| tags | Additional tags | map(string) | no |

## Outputs

| Name | Description |
|------|-------------|
| role_arn | ARN of the IAM role |
| role_name | Name of the IAM role |
| instance_profile_arn | ARN of the instance profile |
| instance_profile_name | Name of the instance profile |

## Testing

1. Copy `sandbox.auto.tfvars.example` to `sandbox.auto.tfvars`
2. Update values as needed
3. Run `terraform init`
4. Run `terraform plan`
5. Run `terraform apply` (in sandbox workspace)

## Compliance

This module follows organizational constitution requirements:
- §1.1: Uses private module registry (`app.terraform.io/ravi-panchal-org`)
- §3.2: Standard file organization
- §3.3: HashiCorp naming conventions
- §3.4: Comprehensive variable declarations with validation
