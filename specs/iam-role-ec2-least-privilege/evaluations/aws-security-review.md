# AWS Security Review: IAM Role with Least Privilege EC2 Access

**Review Date**: 2026-01-14  
**Reviewer**: AWS Security Advisor  
**Configuration**: Terraform IAM Role for EC2 with Least Privilege Access  
**Compliance Frameworks**: AWS Well-Architected Framework Security Pillar, CIS AWS Foundations Benchmark

---

## Executive Summary

This security review evaluates a Terraform configuration that creates an IAM role with least privilege access to EC2 resources. The configuration demonstrates **strong security fundamentals** with proper use of tag-based conditional access and separation of read-only and write operations. 

**Overall Security Posture**: ✅ **GOOD** with minor improvements recommended

**Risk Summary**:
- 🔴 **Critical (P0)**: 0 issues
- 🟠 **High (P1)**: 0 issues  
- 🟡 **Medium (P2)**: 3 issues
- 🟢 **Low (P3)**: 2 issues

**Key Strengths**:
- ✅ Proper least privilege implementation with tag-based conditional access
- ✅ Separation of read-only and instance management permissions
- ✅ Resource-level restrictions using ARN patterns
- ✅ Service-specific trust policy (EC2-only)
- ✅ Proper use of default tags for resource management

**Key Recommendations**:
1. Add session duration constraints to IAM role
2. Implement permissions boundary for defense-in-depth
3. Add external ID or condition keys to trust policy for enhanced security
4. Enable CloudTrail logging verification (operational)
5. Add role description with security classification

---

## Security Findings

### 1. Missing Maximum Session Duration Configuration

**Risk Rating**: Medium  
**Justification**: The IAM role does not explicitly set a maximum session duration, defaulting to 1 hour. While the default is reasonable, explicitly defining session duration as a security control demonstrates defense-in-depth and allows for environment-specific tuning (e.g., shorter sessions in production).

**Finding**: File `main.tf:27-47` - IAM role resource `aws_iam_role.ec2_least_privilege` does not specify the `max_session_duration` parameter.

**Impact**:
- Default 1-hour session may be too long for high-security environments
- Lack of explicit configuration makes security intent unclear
- Cannot enforce shorter session durations for temporary elevated access
- Reduces ability to limit the window of opportunity if credentials are compromised
- Fails to meet SOC 2 CC6.1 (Logical and Physical Access Controls) explicit session timeout requirements

**Recommendation**:
1. Add `max_session_duration` parameter to IAM role resource
2. Set to 3600 seconds (1 hour) for production environments or 1800 seconds (30 minutes) for high-security scenarios
3. Document the rationale for chosen duration
4. Consider shorter durations for roles with write permissions vs. read-only roles

**Code Example**:
```hcl
# Before (implicit default)
resource "aws_iam_role" "ec2_least_privilege" {
  name        = var.role_name
  description = "IAM role with least privilege access to EC2 resources"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = var.role_name
  }
}

# After (explicit security control)
resource "aws_iam_role" "ec2_least_privilege" {
  name                 = var.role_name
  description          = "IAM role with least privilege access to EC2 resources"
  max_session_duration = 3600  # 1 hour - explicit session timeout

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = var.role_name
  }
}

# For high-security environments (production)
resource "aws_iam_role" "ec2_least_privilege" {
  name                 = var.role_name
  description          = "IAM role with least privilege access to EC2 resources"
  max_session_duration = 1800  # 30 minutes - tighter security control

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = var.role_name
  }
}
```

**Source**: [IAM Role Session Duration - AWS IAM User Guide - https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_update-role-settings.html]  
**Reference**: [AWS Well-Architected Framework - Security Pillar - SEC03-BP02 (Grant least privilege access)]  
**Reference**: [IAM Identity Center Session Duration - https://docs.aws.amazon.com/singlesignon/latest/userguide/howtosessionduration.html]

**Effort**: Low (2 minutes to add parameter)

---

### 2. No Permissions Boundary Defined

**Risk Rating**: Medium  
**Justification**: The IAM role lacks a permissions boundary, which is a defense-in-depth mechanism that sets maximum permissions an identity can have. While the current policy is well-scoped, a permissions boundary provides an additional safety layer to prevent privilege escalation if the role policy is modified incorrectly or if future administrators attach overly permissive policies.

**Finding**: File `main.tf:27-47` - IAM role resource `aws_iam_role.ec2_least_privilege` does not specify a `permissions_boundary` parameter.

**Impact**:
- No safety net if role policy is accidentally or maliciously modified to be overly permissive
- Cannot enforce organizational policy on maximum permissions across multiple roles
- Reduced defense-in-depth posture
- Potential for privilege escalation if role is later modified without proper review
- Does not follow AWS Well-Architected Framework recommendation for delegated administration

**Recommendation**:
1. Create a managed policy defining maximum permissions for EC2 operator roles
2. Attach this policy as a permissions boundary to the IAM role
3. Ensure the boundary policy includes only EC2 and essential supporting services (CloudWatch Logs, Systems Manager)
4. Document the permissions boundary in the role description
5. Use AWS Organizations Service Control Policies (SCPs) as an additional layer if managing multiple accounts

**Code Example**:
```hcl
# Before (no permissions boundary)
resource "aws_iam_role" "ec2_least_privilege" {
  name        = var.role_name
  description = "IAM role with least privilege access to EC2 resources"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = var.role_name
  }
}

# After (with permissions boundary for defense-in-depth)

# 1. Create permissions boundary policy
resource "aws_iam_policy" "ec2_permissions_boundary" {
  name        = "EC2OperatorBoundary"
  description = "Maximum permissions boundary for EC2 operator roles"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EC2ServiceBoundary"
        Effect = "Allow"
        Action = [
          "ec2:*"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchLogsBoundary"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
      {
        Sid    = "SystemsManagerBoundary"
        Effect = "Allow"
        Action = [
          "ssm:DescribeParameters",
          "ssm:GetParameter",
          "ssm:GetParameters"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "EC2OperatorBoundary"
    Purpose     = "PermissionsBoundary"
    Environment = var.environment
  }
}

# 2. Apply permissions boundary to role
resource "aws_iam_role" "ec2_least_privilege" {
  name                 = var.role_name
  description          = "IAM role with least privilege access to EC2 resources (Boundary: EC2OperatorBoundary)"
  permissions_boundary = aws_iam_policy.ec2_permissions_boundary.arn

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name               = var.role_name
    PermissionsBoundary = "EC2OperatorBoundary"
  }
}
```

**Source**: [Permissions Boundaries for IAM Entities - AWS IAM User Guide - https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_boundaries.html]  
**Reference**: [AWS Well-Architected Framework - Security Pillar - SEC03-BP02 (Grant least privilege access)]  
**Reference**: [AWS Security Best Practices - Delegate Using Permissions Boundaries - https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html]

**Effort**: Medium (20-30 minutes to define and apply permissions boundary)

---

### 3. Wildcard Actions in Read-Only Access Statement

**Risk Rating**: Medium  
**Justification**: The policy uses wildcard actions (`ec2:Describe*`, `ec2:Get*`, `ec2:List*`) which, while common for read-only access, grant permissions to future AWS EC2 API actions that may be added. This violates strict least privilege principles and could inadvertently grant access to new sensitive operations without explicit review.

**Finding**: File `main.tf:57-66` - IAM policy statement uses wildcard suffix actions for EC2 read operations.

**Impact**:
- Automatic permission grants to future EC2 Describe/Get/List actions without security review
- Potential access to sensitive metadata (e.g., future API calls that expose security group rules, network configurations)
- Reduced audit trail clarity - harder to understand exact permissions granted
- Does not follow CIS AWS Foundations Benchmark strict interpretation of least privilege
- May grant access to describe security-sensitive resources (KMS keys, secrets) if AWS adds new EC2 APIs

**Recommendation**:
1. **Option A (Recommended for high-security environments)**: Replace wildcards with explicit action list based on actual usage
2. **Option B (Pragmatic for operational environments)**: Keep wildcards but add documentation justifying the trade-off
3. Monitor AWS CloudTrail logs to identify actually-used Describe/Get/List actions
4. Use IAM Access Analyzer to generate least-privilege policies based on actual usage
5. Implement periodic policy reviews (quarterly) to validate continued necessity

**Code Example**:
```hcl
# Before (wildcard actions - MEDIUM RISK)
{
  Sid    = "EC2ReadOnlyAccess"
  Effect = "Allow"
  Action = [
    "ec2:Describe*",      # ⚠️ Grants all current and future Describe actions
    "ec2:Get*",           # ⚠️ Grants all current and future Get actions
    "ec2:List*"           # ⚠️ Grants all current and future List actions
  ]
  Resource = "*"
}

# After - Option A (Explicit Actions - MOST SECURE)
{
  Sid    = "EC2ReadOnlyAccess"
  Effect = "Allow"
  Action = [
    # Instance operations
    "ec2:DescribeInstances",
    "ec2:DescribeInstanceStatus",
    "ec2:DescribeInstanceTypes",
    "ec2:DescribeInstanceAttribute",
    "ec2:GetConsoleOutput",
    "ec2:GetConsoleScreenshot",
    
    # Volume operations
    "ec2:DescribeVolumes",
    "ec2:DescribeVolumeStatus",
    "ec2:DescribeVolumeAttribute",
    
    # Network operations
    "ec2:DescribeVpcs",
    "ec2:DescribeSubnets",
    "ec2:DescribeSecurityGroups",
    "ec2:DescribeNetworkInterfaces",
    
    # Image operations
    "ec2:DescribeImages",
    "ec2:DescribeSnapshots",
    
    # Tag operations
    "ec2:DescribeTags",
    
    # Region and availability zones
    "ec2:DescribeRegions",
    "ec2:DescribeAvailabilityZones"
  ]
  Resource = "*"
}

# After - Option B (Documented Wildcards - PRAGMATIC)
{
  Sid    = "EC2ReadOnlyAccess"
  Effect = "Allow"
  Action = [
    "ec2:Describe*",
    "ec2:Get*",
    "ec2:List*"
  ]
  Resource = "*"
  # Note: Wildcard actions used for operational efficiency.
  # Regularly reviewed via CloudTrail access patterns.
  # Read-only actions pose minimal security risk.
  # Reviewed: 2026-01-14 | Next Review: 2026-04-14
}
```

**Additional Mitigation - IAM Access Analyzer Usage**:
```bash
# Use IAM Access Analyzer to generate least-privilege policy from CloudTrail logs
aws accessanalyzer create-policy-generation \
  --policy-generation-details '{
    "principalArn": "arn:aws:iam::123456789012:role/ec2-least-privilege-role"
  }' \
  --cloud-trail-details '{
    "trailArn": "arn:aws:cloudtrail:us-east-1:123456789012:trail/my-trail",
    "startTime": "2026-01-01T00:00:00Z",
    "endTime": "2026-01-14T00:00:00Z",
    "accessRole": "arn:aws:iam::123456789012:role/AccessAnalyzerRole"
  }'
```

**Source**: [IAM Access Analyzer Policy Generation - AWS IAM User Guide - https://docs.aws.amazon.com/IAM/latest/UserGuide/access-analyzer-policy-generation.html]  
**Reference**: [AWS Well-Architected Framework - Security Pillar - SEC03-BP02 (Grant least privilege access)]  
**Reference**: [CIS AWS Foundations Benchmark - §1.16 (Ensure IAM policies are attached only to groups or roles)]

**Effort**: Medium (30-60 minutes to identify and list explicit actions if choosing Option A; Low 5 minutes for Option B documentation)

---

### 4. Missing External ID or Additional Condition Keys in Trust Policy

**Risk Rating**: Low  
**Justification**: The trust policy allows any EC2 instance in the account to assume this role without additional constraints. While appropriate for EC2 instance profiles, adding condition keys (e.g., source VPC, source instance tags) provides defense-in-depth by limiting which EC2 instances can assume the role.

**Finding**: File `main.tf:31-42` - Trust policy (assume role policy) only validates the service principal `ec2.amazonaws.com` without additional condition constraints.

**Impact**:
- Any EC2 instance in the account can assume this role (unless restricted by instance profile attachment)
- No protection against misconfigured instance profile attachments
- Reduced ability to enforce network-based or tag-based isolation
- Lower defense-in-depth posture
- Potential for lateral movement if an attacker compromises any EC2 instance

**Recommendation**:
1. Add condition keys to restrict role assumption based on:
   - Source VPC ID (if instances are in known VPCs)
   - Instance tags (if only specific instance types should assume the role)
   - Source IP ranges (if instances are in known subnets)
2. Use `aws:SourceVpc` or `aws:SourceArn` condition keys
3. Require multi-factor authentication (MFA) for sensitive operations (if applicable)
4. Document the trust policy constraints in the role description

**Code Example**:
```hcl
# Before (basic trust policy)
assume_role_policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }
  ]
})

# After - Option A (VPC-constrained trust policy)
assume_role_policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
      Condition = {
        StringEquals = {
          "aws:SourceVpc" = var.allowed_vpc_id  # Only instances in specified VPC
        }
      }
    }
  ]
})

# After - Option B (Tag-based trust policy)
assume_role_policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
      Condition = {
        StringEquals = {
          "aws:PrincipalTag/Environment" = var.environment
          "aws:PrincipalTag/ManagedBy"   = "Terraform"
        }
      }
    }
  ]
})

# After - Option C (ARN pattern constraint for specific account)
assume_role_policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
    {
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
      Condition = {
        StringLike = {
          "aws:SourceArn" = "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"
        }
      }
    }
  ]
})
```

**Source**: [IAM Role Trust Policies - AWS IAM User Guide - https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-service.html]  
**Reference**: [AWS Global Condition Context Keys - https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_condition-keys.html]  
**Reference**: [Confused Deputy Problem Prevention - https://docs.aws.amazon.com/IAM/latest/UserGuide/confused-deputy.html]

**Effort**: Low (10 minutes to add condition keys, depending on organizational requirements)

---

### 5. No CloudTrail Logging Configuration Verification

**Risk Rating**: Low  
**Justification**: While the Terraform configuration properly creates IAM resources, it does not verify that CloudTrail is enabled to log API calls made using this role. This is an operational security gap rather than a configuration vulnerability, but is essential for audit compliance and incident response.

**Finding**: The Terraform configuration does not include data sources or checks to verify that CloudTrail logging is enabled in the AWS account.

**Impact**:
- Cannot audit actions taken by EC2 instances using this role
- Reduced incident response capability - no forensic trail
- Compliance violations (SOC 2, PCI-DSS, HIPAA require audit logging)
- Difficulty detecting compromised instances or privilege escalation attempts
- Violates CIS AWS Foundations Benchmark requirement for CloudTrail logging

**Recommendation**:
1. Add Terraform data source to verify CloudTrail is enabled
2. Add CloudTrail trail resource if not externally managed
3. Enable CloudTrail Insights for anomaly detection
4. Configure CloudTrail to log to S3 bucket with encryption and lifecycle policies
5. Set up CloudWatch Logs integration for real-time alerting
6. Document logging requirements in README.md

**Code Example**:
```hcl
# Add to main.tf - CloudTrail verification

# Data source to check for existing CloudTrail trail
data "aws_cloudtrail_service_account" "main" {}

# Verify CloudTrail exists (will fail if not configured)
data "aws_cloudtrail" "security_trail" {
  name = "organization-trail"  # Replace with your trail name
}

# Optional: Create CloudTrail if managing within this module
resource "aws_cloudtrail" "security_trail" {
  count = var.create_cloudtrail ? 1 : 0

  name                          = "ec2-role-security-trail"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs[0].id
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
  
  event_selector {
    read_write_type           = "All"
    include_management_events = true
  }

  # Enable CloudTrail Insights for anomaly detection
  insight_selector {
    insight_type = "ApiCallRateInsight"
  }

  tags = {
    Name        = "ec2-role-security-trail"
    Environment = var.environment
  }
}

# S3 bucket for CloudTrail logs (if creating CloudTrail)
resource "aws_s3_bucket" "cloudtrail_logs" {
  count = var.create_cloudtrail ? 1 : 0

  bucket = "cloudtrail-logs-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "CloudTrail Logs"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  count = var.create_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail_logs[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  count = var.create_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail_logs[0].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  count = var.create_cloudtrail ? 1 : 0

  bucket = aws_s3_bucket.cloudtrail_logs[0].id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Add variable to control CloudTrail creation
variable "create_cloudtrail" {
  description = "Whether to create CloudTrail trail (set to false if CloudTrail is managed separately)"
  type        = bool
  default     = false
}
```

**Alternative - Documentation-Only Approach**:
```markdown
# Add to README.md

## Security Requirements

### CloudTrail Logging (MANDATORY)

This IAM role **requires** CloudTrail logging to be enabled in the AWS account for compliance and audit purposes.

**Verification Steps**:
1. Verify CloudTrail is enabled:
   ```bash
   aws cloudtrail describe-trails --region us-east-1
   ```

2. Verify CloudTrail is logging:
   ```bash
   aws cloudtrail get-trail-status --name <trail-name>
   ```

3. Ensure CloudTrail logs include:
   - ✅ Management events
   - ✅ Data events (for sensitive resources)
   - ✅ Multi-region trail
   - ✅ Log file validation enabled

**Compliance Requirements**:
- CIS AWS Foundations Benchmark §2.1-2.9 (CloudTrail configuration)
- SOC 2 CC7.2 (System Monitoring)
- PCI-DSS 10.2 (Audit Logging)
```

**Source**: [AWS CloudTrail - AWS Documentation - https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-user-guide.html]  
**Reference**: [CIS AWS Foundations Benchmark - §2.1 (Ensure CloudTrail is enabled in all regions)]  
**Reference**: [AWS Well-Architected Framework - Security Pillar - SEC04-BP01 (Configure service and application logging)]

**Effort**: Low (10 minutes for documentation; Medium 30 minutes if implementing CloudTrail resources)

---

## Compliance Matrix

| Compliance Framework | Control | Status | Notes |
|---------------------|---------|--------|-------|
| **AWS Well-Architected Framework** | | | |
| SEC03-BP02 | Grant least privilege access | ✅ Pass | Excellent use of tag-based conditions |
| SEC03-BP03 | Establish emergency access process | ⚠️ N/A | Not applicable to this role |
| SEC02-BP02 | Use temporary credentials | ✅ Pass | Uses IAM role (temporary credentials) |
| SEC04-BP01 | Configure service and application logging | ⚠️ Advisory | Recommend verifying CloudTrail enabled |
| **CIS AWS Foundations Benchmark** | | | |
| 1.16 | Ensure IAM policies are attached only to groups or roles | ✅ Pass | Policy attached to role, not users |
| 1.15 | Ensure security questions are registered | ⚠️ N/A | Not applicable to service roles |
| 2.1 | Ensure CloudTrail is enabled in all regions | ⚠️ Advisory | Should verify externally |
| 2.7 | Ensure CloudTrail logs are encrypted at rest | ⚠️ Advisory | Should verify externally |
| **SOC 2 Trust Service Criteria** | | | |
| CC6.1 | Logical and Physical Access Controls | ✅ Pass | Proper access restrictions |
| CC6.2 | Authorization of new accounts | ✅ Pass | Tag-based authorization controls |
| CC7.2 | System Monitoring | ⚠️ Advisory | Recommend CloudTrail verification |
| **NIST Cybersecurity Framework** | | | |
| PR.AC-4 | Least privilege | ✅ Pass | Excellent implementation |
| PR.AC-1 | Identity management | ✅ Pass | Proper IAM role configuration |
| DE.CM-1 | Network monitoring | ⚠️ Advisory | Recommend VPC Flow Logs |

**Legend**:
- ✅ **Pass**: Fully compliant with control requirements
- ⚠️ **Advisory**: Meets minimum requirements, improvements recommended
- ❌ **Fail**: Does not meet control requirements (none found)
- N/A: Not applicable to this configuration

---

## Positive Security Practices Identified

The following security best practices are correctly implemented in this configuration:

### 1. ✅ Excellent Tag-Based Conditional Access (main.tf:76-79)
```hcl
Condition = {
  StringEquals = {
    "aws:ResourceTag/ManagedBy" = "Terraform"
  }
}
```
- **Best Practice**: Restricts instance management actions to only instances tagged `ManagedBy=Terraform`
- **Impact**: Prevents accidental or malicious actions on unmanaged instances
- **Alignment**: AWS Well-Architected SEC03-BP02, CIS 1.16

### 2. ✅ Resource-Level ARN Restrictions (main.tf:75)
```hcl
Resource = "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"
```
- **Best Practice**: Limits instance management to specific region and account
- **Impact**: Prevents cross-region or cross-account actions
- **Alignment**: AWS Well-Architected SEC03-BP02

### 3. ✅ Separation of Read and Write Permissions (main.tf:57-82)
- **Best Practice**: Separates read-only access (Describe/Get/List) from write operations (Start/Stop/Reboot)
- **Impact**: Clear delineation of privilege levels, easier audit and review
- **Alignment**: Principle of Least Privilege

### 4. ✅ Service-Specific Trust Policy (main.tf:36-38)
```hcl
Principal = {
  Service = "ec2.amazonaws.com"
}
```
- **Best Practice**: Role can only be assumed by EC2 service, not by users or other services
- **Impact**: Reduces attack surface, prevents unauthorized role assumption
- **Alignment**: AWS IAM Best Practices

### 5. ✅ Terraform Input Validation (variables.tf:18-21)
```hcl
validation {
  condition     = can(regex("^[a-zA-Z0-9-_]+$", var.role_name))
  error_message = "Role name must contain only alphanumeric characters, hyphens, and underscores."
}
```
- **Best Practice**: Validates role name format to prevent injection attacks
- **Impact**: Reduces risk of malformed resource names causing security issues
- **Alignment**: Secure Development Practices

### 6. ✅ Comprehensive Resource Tagging (main.tf:17-23, 44-46, 85-87)
- **Best Practice**: Consistent tagging strategy across all resources
- **Impact**: Enables cost allocation, access control, and resource management
- **Alignment**: AWS Tagging Best Practices

### 7. ✅ Use of Data Sources for Dynamic Values (main.tf:107)
```hcl
data "aws_caller_identity" "current" {}
```
- **Best Practice**: Dynamically retrieves account ID instead of hardcoding
- **Impact**: Improves portability and reduces configuration errors
- **Alignment**: Infrastructure as Code Best Practices

---

## Security Architecture Review

### Defense-in-Depth Analysis

| Layer | Control | Status | Notes |
|-------|---------|--------|-------|
| **Identity** | IAM Role (not user) | ✅ Strong | Uses temporary credentials |
| **Authentication** | Service principal trust | ✅ Good | EC2-only trust policy |
| **Authorization** | Least privilege policy | ✅ Strong | Tag-based conditions |
| **Authorization** | Permissions boundary | ⚠️ Missing | Recommended for defense-in-depth |
| **Audit** | CloudTrail logging | ⚠️ External | Should verify enabled |
| **Audit** | Session duration | ⚠️ Default | Should explicitly configure |
| **Network** | VPC constraints | ⚠️ None | Optional trust policy conditions |
| **Data** | Resource restrictions | ✅ Strong | ARN-based limitations |

### Attack Surface Analysis

**Potential Attack Vectors**:
1. **Compromised EC2 Instance**: 
   - Risk: Attacker gains access to EC2 instance with this role attached
   - Mitigation: Tag-based conditions limit blast radius to only tagged instances
   - Residual Risk: Low (well-mitigated)

2. **Policy Modification**:
   - Risk: Administrator accidentally adds overly permissive policies
   - Mitigation: None (permissions boundary would mitigate)
   - Residual Risk: Medium (can be reduced with permissions boundary)

3. **Privilege Escalation**:
   - Risk: Attacker attempts to escalate privileges beyond EC2 access
   - Mitigation: Policy only grants EC2 permissions, no IAM/Lambda/etc.
   - Residual Risk: Low (well-mitigated)

4. **Lateral Movement**:
   - Risk: Attacker uses compromised instance to access other instances
   - Mitigation: Instance management limited to tagged resources
   - Residual Risk: Low (well-mitigated)

**Overall Attack Surface**: ✅ **LOW** - Well-designed security controls

---

## Remediation Priority

### Immediate Actions (Within 24 hours)
None - No critical or high-risk findings identified.

### Short-Term Actions (Within 1 week)
1. **Add maximum session duration** to IAM role (Finding #1)
2. **Document wildcard action usage** or replace with explicit actions (Finding #3)
3. **Verify CloudTrail is enabled** and document in README (Finding #5)

### Medium-Term Actions (Within 1 month)
1. **Implement permissions boundary** for defense-in-depth (Finding #2)
2. **Add condition keys to trust policy** if VPC/tag constraints are applicable (Finding #4)

### Long-Term Actions (Within 1 quarter)
1. **Establish periodic policy review process** (quarterly)
2. **Implement IAM Access Analyzer** for continuous least-privilege validation
3. **Consider AWS Organizations SCPs** if managing multiple accounts

---

## Security Testing Recommendations

### 1. IAM Policy Simulator Testing
```bash
# Test if role can perform intended actions
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:role/ec2-least-privilege-role \
  --action-names ec2:DescribeInstances ec2:StartInstances \
  --resource-arns arn:aws:ec2:us-east-1:123456789012:instance/i-1234567890abcdef0

# Test if role is blocked from unintended actions
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:role/ec2-least-privilege-role \
  --action-names iam:CreateUser s3:PutObject lambda:InvokeFunction \
  --resource-arns "*"
```

### 2. Tag-Based Condition Testing
```bash
# Test starting instance WITH required tag (should succeed)
aws ec2 start-instances \
  --instance-ids i-1234567890abcdef0 \
  --profile ec2-role-test

# Test starting instance WITHOUT required tag (should fail)
aws ec2 start-instances \
  --instance-ids i-untagged-instance \
  --profile ec2-role-test
```

### 3. CloudTrail Audit Verification
```bash
# Verify CloudTrail logs role usage
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceName,AttributeValue=ec2-least-privilege-role \
  --max-results 10
```

### 4. IAM Access Analyzer Validation
```bash
# Use Access Analyzer to validate policy
aws accessanalyzer validate-policy \
  --policy-document file://policy.json \
  --policy-type IDENTITY_POLICY
```

---

## Additional Security Recommendations

### 1. Monitoring and Alerting

**Implement CloudWatch Alarms**:
```hcl
# Add to main.tf - CloudWatch alarms for role usage monitoring

resource "aws_cloudwatch_log_metric_filter" "unauthorized_api_calls" {
  name           = "UnauthorizedEC2RoleAPICalls"
  log_group_name = "/aws/cloudtrail/organization-trail"
  pattern        = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") && ($.userIdentity.sessionContext.sessionIssuer.arn = \"*ec2-least-privilege-role*\") }"

  metric_transformation {
    name      = "UnauthorizedEC2RoleAPICallCount"
    namespace = "Security/IAM"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "unauthorized_api_calls" {
  alarm_name          = "EC2Role-UnauthorizedAPICalls"
  alarm_description   = "Alert on unauthorized API calls using EC2 least privilege role"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "UnauthorizedEC2RoleAPICallCount"
  namespace           = "Security/IAM"
  period              = "300"
  statistic           = "Sum"
  threshold           = "1"
  treat_missing_data  = "notBreaching"

  alarm_actions = [var.security_sns_topic_arn]
}
```

### 2. Security Hub Integration

Enable AWS Security Hub to continuously monitor IAM role compliance:
```bash
# Enable Security Hub
aws securityhub enable-security-hub --enable-default-standards

# Enable IAM Access Analyzer
aws accessanalyzer create-analyzer \
  --analyzer-name organization-analyzer \
  --type ORGANIZATION
```

### 3. Regular Access Reviews

Implement quarterly access reviews:
1. Review CloudTrail logs for actual API usage
2. Identify unused permissions using IAM Access Analyzer
3. Refine policy to remove unnecessary permissions
4. Document review findings and policy changes

### 4. Incident Response Procedures

**If role is compromised**:
1. Immediately detach policy from role
2. Revoke active sessions (rotate role credentials)
3. Review CloudTrail logs for unauthorized actions
4. Rotate any exposed credentials or secrets
5. Conduct root cause analysis
6. Update security controls based on findings

---

## Conclusion

**Overall Security Rating**: ✅ **EXCELLENT**

This Terraform configuration demonstrates **strong security fundamentals** and follows AWS best practices for least privilege IAM role design. The use of tag-based conditional access, resource-level ARN restrictions, and service-specific trust policies shows mature security architecture.

**Key Strengths**:
- ✅ Proper implementation of least privilege principle
- ✅ Tag-based conditional access for instance management
- ✅ Clear separation of read-only and write permissions
- ✅ Resource-level restrictions using ARN patterns
- ✅ Service-specific trust policy

**Recommended Improvements** (all Medium/Low priority):
- Add explicit maximum session duration
- Implement permissions boundary for defense-in-depth
- Replace wildcards with explicit actions OR document usage
- Add condition keys to trust policy (if applicable)
- Verify CloudTrail logging is enabled

**No critical or high-risk vulnerabilities identified.** The configuration is suitable for production use with minor improvements.

---

## References

### AWS Documentation
1. [AWS Well-Architected Framework - Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/)
2. [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
3. [Grant Least Privilege Access](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/sec_permissions_least_privileges.html)
4. [Permissions Boundaries for IAM Entities](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_boundaries.html)
5. [IAM Role Session Duration](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_update-role-settings.html)
6. [Tag-Based Access Control](https://docs.aws.amazon.com/IAM/latest/UserGuide/access_iam-tags.html)
7. [AWS CloudTrail User Guide](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/)
8. [IAM Access Analyzer](https://docs.aws.amazon.com/IAM/latest/UserGuide/access-analyzer-getting-started.html)

### Compliance Frameworks
1. [CIS AWS Foundations Benchmark v1.5.0](https://www.cisecurity.org/benchmark/amazon_web_services)
2. [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
3. [SOC 2 Trust Service Criteria](https://www.aicpa.org/interestareas/frc/assuranceadvisoryservices/aicpasoc2report.html)

### Additional Resources
1. [AWS Security Blog](https://aws.amazon.com/blogs/security/)
2. [IAM Policy Simulator](https://policysim.aws.amazon.com/)
3. [AWS Security Hub](https://aws.amazon.com/security-hub/)

---

**Review Completed**: 2026-01-14  
**Next Review Due**: 2026-04-14 (Quarterly)  
**Reviewed By**: AWS Security Advisor  
**Approval Status**: ✅ Approved for Production (with minor improvements recommended)
