# AWS Security Review: IAM Role EC2 Least Privilege Configuration

**Review Date**: 2026-01-14  
**Feature**: IAM Role for EC2 with Least Privilege Access  
**Reviewer**: AWS Security Advisor  
**Context**: Production-grade Terraform configuration for EC2 IAM role with read-only and conditional write permissions

---

## Executive Summary

This security review analyzes a Terraform IAM configuration that creates an IAM role for EC2 instances with least privilege access patterns. The configuration demonstrates several **strong security practices**, including:

✅ Use of External ID for confused deputy protection  
✅ Tag-based conditional access controls  
✅ Resource tagging for governance  
✅ Input validation on variables  
✅ Service-scoped trust policy (EC2 only)

However, **3 Medium-severity and 2 Low-severity findings** were identified that should be addressed before production deployment. **No Critical or High-severity vulnerabilities** were found.

**Overall Security Posture**: **GOOD** ✅  
**Recommended Action**: Address Medium findings before production deployment

---

## Security Findings

### Finding 1: External ID Implementation Issue for EC2 Service Principal

**Risk Rating**: Medium  
**Justification**: The External ID condition in the trust policy is **incompatible** with EC2 service principal assumptions. External IDs are designed for cross-account third-party access scenarios, not for EC2 service-to-service authentication. This misconfiguration will **prevent EC2 instances from assuming the role**, causing deployment failures.

**Finding**: File `main.tf:38-52` implements an `sts:ExternalId` condition in the trust policy for the `ec2.amazonaws.com` service principal.

```hcl
# main.tf:38-52
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    
    actions = ["sts:AssumeRole"]
    
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.external_id]
    }
  }
}
```

**Impact**:
- **EC2 instances will fail to assume the role** at launch time
- Instance profile attachment will succeed, but credential retrieval will fail
- Applications running on EC2 will receive "Access Denied" errors
- Deployment failures and operational disruptions
- Misleading security control that provides no actual protection

**Root Cause Analysis**:
External IDs are specifically designed for the **confused deputy problem** in cross-account scenarios where a third-party service (like a monitoring vendor) assumes roles in multiple customer accounts. The EC2 service principal (`ec2.amazonaws.com`) does not and cannot pass an External ID when assuming roles on behalf of instances.

**Recommendation**:

1. **Remove the External ID condition** from the trust policy for EC2 service principal
2. If cross-account access is required, use a separate trust policy statement with AWS account principals
3. For EC2 service principal, rely on **instance profile attachment** as the security boundary
4. Consider implementing additional conditions for defense-in-depth:
   - `aws:SourceAccount` - Restricts to your AWS account
   - `aws:SourceArn` - Restricts to specific instance ARNs (if known)
   - `ec2:SourceInstanceARN` - Restricts based on instance identity

**Code Example**:

```hcl
# Before (MISCONFIGURED - WILL FAIL)
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    
    actions = ["sts:AssumeRole"]
    
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.external_id]  # ❌ EC2 service cannot pass External ID
    }
  }
}

# After (CORRECT - EC2 Service Principal)
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    sid    = "EC2ServiceAssumeRole"
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    
    actions = ["sts:AssumeRole"]
    
    # Optional: Add account-level protection
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
}

# If you need External ID for third-party cross-account access, add a SEPARATE statement:
data "aws_iam_policy_document" "assume_role_policy_with_third_party" {
  statement {
    sid    = "EC2ServiceAssumeRole"
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    
    actions = ["sts:AssumeRole"]
    
    condition {
      test     = "StringEquals"
      variable = "aws:SourceAccount"
      values   = [data.aws_caller_identity.current.account_id]
    }
  }
  
  statement {
    sid    = "ThirdPartyAssumeRole"
    effect = "Allow"
    
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::123456789012:root"]  # Third-party AWS account
    }
    
    actions = ["sts:AssumeRole"]
    
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.external_id]  # ✅ CORRECT for cross-account access
    }
  }
}

# Add data source for current account ID
data "aws_caller_identity" "current" {}
```

**Source**: [AWS IAM - Providing access to third parties - https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_common-scenarios_third-party.html]  
**Reference**: [AWS Well-Architected Framework - Security Pillar - SEC03-BP09 - Share resources securely with third parties]  
**Quote from AWS Documentation**: 
> "Use an external ID in the following situations: You are an AWS account owner and you have configured a role for a third party that accesses other AWS accounts in addition to yours."

**Effort**: Low (10 minutes to update trust policy and test)

---

### Finding 2: Overly Broad EC2 Read-Only Permissions with Wildcard Resources

**Risk Rating**: Medium  
**Justification**: The policy grants broad read access to ALL EC2 resources using wildcard actions (`ec2:Describe*`, `ec2:Get*`, `ec2:List*`) and wildcard resources (`*`). While read-only, this violates the principle of least privilege and may expose sensitive infrastructure information that could aid reconnaissance for attacks.

**Finding**: File `main.tf:56-65` grants unrestricted read access to all EC2 resources.

```hcl
# main.tf:56-65
statement {
  sid    = "EC2ReadOnly"
  effect = "Allow"
  actions = [
    "ec2:Describe*",
    "ec2:Get*",
    "ec2:List*"
  ]
  resources = ["*"]
}
```

**Impact**:
- **Information disclosure risk**: Exposes complete EC2 infrastructure topology
- Reveals security group configurations, network architecture, and AMI details
- Aids reconnaissance for lateral movement or privilege escalation attacks
- Compliance violations: May not meet "need-to-know" requirements (NIST 800-53 AC-3)
- Broader access than required for typical EC2 management operations

**Sensitive Information Exposed**:
- Security group rules and network access controls
- VPC configurations and subnet layouts
- Private IP addresses and network topology
- Instance metadata (AMI IDs, instance types, user data)
- Snapshot and volume encryption status
- Key pair names and associations

**Recommendation**:

1. **Replace wildcard actions with specific, required actions only**
2. **Evaluate actual business requirements** - What specific information does the role need to read?
3. Consider scoping to specific resource types if wildcards are unavoidable
4. Use condition keys to limit scope where possible (e.g., by tag, region)
5. Implement CloudTrail logging to audit what permissions are actually used
6. Use **IAM Access Analyzer** to identify unused permissions after deployment

**Code Example**:

```hcl
# Before (OVERLY BROAD)
statement {
  sid    = "EC2ReadOnly"
  effect = "Allow"
  actions = [
    "ec2:Describe*",    # ❌ Grants 100+ Describe actions
    "ec2:Get*",         # ❌ Grants 20+ Get actions
    "ec2:List*"         # ❌ Grants multiple List actions
  ]
  resources = ["*"]     # ❌ All resources in account
}

# After (LEAST PRIVILEGE - Example for instance monitoring use case)
statement {
  sid    = "EC2InstanceReadOnly"
  effect = "Allow"
  actions = [
    # Only actions required for instance monitoring/management
    "ec2:DescribeInstances",
    "ec2:DescribeInstanceStatus",
    "ec2:DescribeInstanceAttribute",
    "ec2:DescribeTags"
  ]
  resources = ["*"]  # Note: These actions don't support resource-level permissions
  
  # Optional: Restrict by tag to only see managed instances
  condition {
    test     = "StringEquals"
    variable = "ec2:ResourceTag/ManagedBy"
    values   = [var.role_name]
  }
}

# If volume information is needed
statement {
  sid    = "EC2VolumeReadOnly"
  effect = "Allow"
  actions = [
    "ec2:DescribeVolumes",
    "ec2:DescribeVolumeStatus"
  ]
  resources = ["*"]  # These actions don't support resource-level permissions
}

# If security group read access is required (use with caution)
statement {
  sid    = "EC2SecurityGroupReadOnly"
  effect = "Allow"
  actions = [
    "ec2:DescribeSecurityGroups",
    "ec2:DescribeSecurityGroupRules"
  ]
  resources = ["*"]
  
  # Optional: Limit to specific VPC
  condition {
    test     = "StringEquals"
    variable = "ec2:Vpc"
    values   = ["arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:vpc/${var.vpc_id}"]
  }
}
```

**Important Note on EC2 Describe Actions**:
According to AWS documentation, most EC2 `Describe*`, `Get*`, and `List*` actions **do not support resource-level permissions** and require `"Resource": "*"` in the policy. This is an AWS service limitation, not a configuration error. However, you can still apply **condition keys** to limit scope.

**Source**: [AWS EC2 IAM Policies - Console Access - https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-policies-ec2-console.html]  
**Reference**: [AWS Well-Architected Framework - Security Pillar - SEC02-BP02 - Grant least privilege access]  
**Reference**: [CIS AWS Foundations Benchmark - §1.16 - Ensure IAM policies with administrative privileges are not attached]  
**Quote from AWS Documentation**: 
> "The ec2:Describe* API actions do not support resource-level permissions, so the * wildcard is necessary in the Resource element of the policy statements."

**Effort**: Medium (30-60 minutes to identify required actions and test functionality)

---

### Finding 3: Missing CloudTrail Logging for Role Assumption and API Activity

**Risk Rating**: Medium  
**Justification**: The configuration does not include CloudTrail integration for auditing role assumption events and API actions performed using this role. This creates a **security observability gap**, making it difficult to detect unauthorized access, perform incident response, or meet compliance requirements.

**Finding**: No CloudTrail configuration or logging requirements are defined in the Terraform code. Role assumption events and API calls using this role will only be logged if CloudTrail is separately configured at the account/organizational level.

**Impact**:
- **Lack of audit trail** for role assumption events (`sts:AssumeRole`)
- Inability to detect unauthorized access or credential compromise
- Compliance violations: SOC 2, PCI-DSS, HIPAA, and FedRAMP require audit logging
- Difficult incident response and forensic investigation
- No alerting on suspicious activity patterns
- Violates AWS Well-Architected Security Pillar observability requirements

**Compliance Requirements**:
- **SOC 2 CC6.2**: Systems must log security events
- **PCI-DSS 10.2**: Audit logging of user actions required
- **NIST 800-53 AU-2**: System must log security-relevant events
- **CIS AWS Benchmark 3.1-3.11**: CloudTrail logging requirements

**Recommendation**:

1. **Document CloudTrail prerequisites** in README.md
2. Add CloudTrail configuration as part of the Terraform module (if managing logging)
3. Implement **CloudWatch Log Insights** or **EventBridge** rules for monitoring:
   - Failed role assumption attempts
   - Unusual API call patterns
   - Permissions boundary violations
4. Consider implementing **AWS CloudTrail Insights** for anomaly detection
5. Set up **GuardDuty** integration for threat detection
6. Create CloudWatch alarms for security-relevant events

**Code Example**:

```hcl
# Add to main.tf or create separate cloudtrail.tf

# CloudWatch Log Group for CloudTrail
resource "aws_cloudwatch_log_group" "cloudtrail" {
  name              = "/aws/cloudtrail/${var.role_name}"
  retention_in_days = 90  # Adjust based on compliance requirements
  kms_key_id        = var.kms_key_arn  # Optional: encrypt logs

  tags = merge(
    var.tags,
    {
      Name      = "cloudtrail-${var.role_name}"
      ManagedBy = "Terraform"
    }
  )
}

# IAM Role for CloudTrail to CloudWatch Logs
resource "aws_iam_role" "cloudtrail_cloudwatch" {
  name = "${var.role_name}-cloudtrail-cloudwatch"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "cloudtrail.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cloudtrail_cloudwatch" {
  name = "cloudtrail-cloudwatch-logs"
  role = aws_iam_role.cloudtrail_cloudwatch.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
    }]
  })
}

# CloudTrail for role-specific audit logging
resource "aws_cloudtrail" "role_audit" {
  name                          = "${var.role_name}-audit-trail"
  s3_bucket_name                = var.cloudtrail_bucket_name
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn    = "${aws_cloudwatch_log_group.cloudtrail.arn}:*"
  cloud_watch_logs_role_arn     = aws_iam_role.cloudtrail_cloudwatch.arn
  kms_key_id                    = var.kms_key_arn  # Optional: encrypt trail

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    # Optional: Data events for S3/Lambda if needed
    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::${var.monitored_bucket_name}/*"]
    }
  }

  tags = merge(
    var.tags,
    {
      Name      = "${var.role_name}-audit-trail"
      ManagedBy = "Terraform"
    }
  )
}

# CloudWatch Alarm: Failed AssumeRole attempts
resource "aws_cloudwatch_log_metric_filter" "failed_assume_role" {
  name           = "${var.role_name}-failed-assume-role"
  log_group_name = aws_cloudwatch_log_group.cloudtrail.name
  
  pattern = <<PATTERN
{
  ($.eventName = "AssumeRole") &&
  ($.errorCode = "AccessDenied") &&
  ($.requestParameters.roleArn = "*${aws_iam_role.ec2_least_privilege.name}*")
}
PATTERN

  metric_transformation {
    name      = "FailedAssumeRoleAttempts"
    namespace = "IAMSecurity"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "failed_assume_role" {
  alarm_name          = "${var.role_name}-failed-assume-role-alert"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "FailedAssumeRoleAttempts"
  namespace           = "IAMSecurity"
  period              = 300
  statistic           = "Sum"
  threshold           = 3
  alarm_description   = "Alert on multiple failed AssumeRole attempts"
  alarm_actions       = [var.sns_topic_arn]  # Send to SNS for notifications
}

# EventBridge rule for real-time monitoring
resource "aws_cloudwatch_event_rule" "assume_role_events" {
  name        = "${var.role_name}-assume-role-monitor"
  description = "Monitor AssumeRole events for ${var.role_name}"

  event_pattern = jsonencode({
    source      = ["aws.sts"]
    detail-type = ["AWS API Call via CloudTrail"]
    detail = {
      eventName = ["AssumeRole"]
      requestParameters = {
        roleArn = [{
          prefix = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.role_name}"
        }]
      }
    }
  })
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.assume_role_events.name
  target_id = "SendToSNS"
  arn       = var.sns_topic_arn
}
```

**Alternative: Documentation Approach** (if CloudTrail is managed separately):

Add to `README.md`:

```markdown
## Security & Compliance Prerequisites

### CloudTrail Logging (Required)

This IAM role requires CloudTrail to be enabled for audit logging and compliance:

1. **Enable CloudTrail** at the account or organization level
2. **Required events**: Management events (including STS AssumeRole)
3. **Recommended**: Multi-region trail with log file validation
4. **Recommended**: CloudWatch Logs integration for real-time monitoring
5. **Compliance**: Required for SOC 2, PCI-DSS, HIPAA, and FedRAMP

#### Monitoring Recommendations

- Set up CloudWatch alarms for failed AssumeRole attempts
- Monitor EC2 instance start/stop actions using this role
- Enable AWS GuardDuty for threat detection
- Review CloudTrail logs regularly for unauthorized access

#### Example CloudTrail Query (CloudWatch Logs Insights)

```sql
fields @timestamp, userIdentity.principalId, eventName, errorCode
| filter eventName = "AssumeRole" 
| filter requestParameters.roleArn like /ec2-least-privilege-role/
| sort @timestamp desc
```
```

**Source**: [AWS CloudTrail - Logging IAM and STS API calls - https://docs.aws.amazon.com/awscloudtrail/latest/userguide/cloudtrail-concepts.html]  
**Reference**: [AWS Well-Architected Framework - Security Pillar - SEC04-BP01 - Configure service and application logging]  
**Reference**: [CIS AWS Foundations Benchmark - §3.1 - Ensure CloudTrail is enabled in all regions]  
**Reference**: [NIST 800-53 - AU-2 - Audit Events]

**Effort**: Medium-High (2-4 hours for full CloudTrail/monitoring setup) or Low (30 minutes for documentation)

---

### Finding 4: Missing IAM Permission Boundary

**Risk Rating**: Low  
**Justification**: The IAM role does not implement a **permissions boundary**, which is a defense-in-depth control to prevent privilege escalation. While not required for all use cases, permission boundaries are an AWS best practice for limiting the maximum permissions a role can have, especially in multi-tenant or delegated admin scenarios.

**Finding**: No `permissions_boundary` attribute is set on the `aws_iam_role` resource in `main.tf:17-31`.

**Impact**:
- **No guardrails** against future policy modifications that grant excessive permissions
- Risk of privilege escalation if role is compromised and used to modify its own permissions
- Reduced defense-in-depth posture
- May not meet organizational security standards for delegated administration

**Use Cases for Permission Boundaries**:
- Multi-tenant AWS environments
- Delegated IAM administration
- Development/sandbox environments
- Third-party integrations
- Compliance with organizational security policies

**Recommendation**:

1. Implement a **permissions boundary** for the IAM role
2. Define organizational-level permission boundaries using AWS Organizations SCPs
3. Document permissions boundary policy requirements
4. Consider implementing boundaries for all roles that can modify IAM resources

**Code Example**:

```hcl
# Before (NO PERMISSION BOUNDARY)
resource "aws_iam_role" "ec2_least_privilege" {
  name               = var.role_name
  description        = "IAM Role with least privilege access to EC2 resources"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  # ❌ No permissions_boundary defined

  tags = merge(
    var.tags,
    {
      Name        = var.role_name
      ManagedBy   = "Terraform"
      Purpose     = "EC2 Least Privilege Access"
    }
  )
}

# After (WITH PERMISSION BOUNDARY)
# First, create the permissions boundary policy
data "aws_iam_policy_document" "permission_boundary" {
  # Allow EC2 and CloudWatch actions only
  statement {
    sid    = "AllowedServices"
    effect = "Allow"
    actions = [
      "ec2:*",
      "cloudwatch:*"
    ]
    resources = ["*"]
  }
  
  # Deny ability to modify IAM (prevents privilege escalation)
  statement {
    sid    = "DenyIAMModification"
    effect = "Deny"
    actions = [
      "iam:CreateUser",
      "iam:CreateRole",
      "iam:CreatePolicy",
      "iam:AttachUserPolicy",
      "iam:AttachRolePolicy",
      "iam:PutUserPolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePermissionsBoundary"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "permission_boundary" {
  name        = "${var.role_name}-permission-boundary"
  description = "Permission boundary for ${var.role_name}"
  policy      = data.aws_iam_policy_document.permission_boundary.json

  tags = merge(
    var.tags,
    {
      Name      = "${var.role_name}-permission-boundary"
      ManagedBy = "Terraform"
    }
  )
}

resource "aws_iam_role" "ec2_least_privilege" {
  name                 = var.role_name
  description          = "IAM Role with least privilege access to EC2 resources"
  assume_role_policy   = data.aws_iam_policy_document.assume_role_policy.json
  permissions_boundary = aws_iam_policy.permission_boundary.arn  # ✅ Added boundary

  tags = merge(
    var.tags,
    {
      Name        = var.role_name
      ManagedBy   = "Terraform"
      Purpose     = "EC2 Least Privilege Access"
    }
  )
}

# Optional: Add variable for permission boundary
variable "permissions_boundary_arn" {
  description = "ARN of the IAM policy to use as permissions boundary (optional)"
  type        = string
  default     = ""
}

# Use variable if provided
resource "aws_iam_role" "ec2_least_privilege_flexible" {
  name                 = var.role_name
  description          = "IAM Role with least privilege access to EC2 resources"
  assume_role_policy   = data.aws_iam_policy_document.assume_role_policy.json
  permissions_boundary = var.permissions_boundary_arn != "" ? var.permissions_boundary_arn : null

  tags = merge(
    var.tags,
    {
      Name        = var.role_name
      ManagedBy   = "Terraform"
      Purpose     = "EC2 Least Privilege Access"
    }
  )
}
```

**Source**: [AWS IAM - Permissions boundaries for IAM entities - https://docs.aws.amazon.com/IAM/latest/UserGuide/access_policies_boundaries.html]  
**Reference**: [AWS Well-Architected Framework - Security Pillar - SEC02-BP03 - Establish emergency access process]  
**Reference**: [AWS Security Best Practices - Defense in Depth]

**Effort**: Low-Medium (30-60 minutes to design and implement boundary policy)

---

### Finding 5: Missing Role Session Duration Configuration

**Risk Rating**: Low  
**Justification**: The IAM role does not specify a `max_session_duration`, which defaults to 1 hour (3600 seconds). For long-running applications or batch processes on EC2, this may cause unnecessary credential refreshes. Conversely, for high-security environments, a shorter session duration provides defense-in-depth by limiting credential validity windows.

**Finding**: No `max_session_duration` attribute is set on the `aws_iam_role` resource in `main.tf:17-31`.

**Impact**:
- **Default 1-hour session duration** may not align with operational or security requirements
- Longer durations (up to 12 hours) reduce credential refresh overhead
- Shorter durations (minimum 1 hour) limit exposure window if credentials are compromised
- Missed opportunity for defense-in-depth hardening

**Recommendation**:

1. **Explicitly set `max_session_duration`** based on use case:
   - High-security: 1 hour (3600 seconds) - default
   - Standard workloads: 4 hours (14400 seconds)
   - Long-running processes: 12 hours (43200 seconds) - maximum
2. Document session duration requirements
3. Consider shorter durations for internet-facing or high-risk workloads
4. Implement credential refresh logic in applications

**Code Example**:

```hcl
# Before (DEFAULT 1-HOUR SESSION)
resource "aws_iam_role" "ec2_least_privilege" {
  name               = var.role_name
  description        = "IAM Role with least privilege access to EC2 resources"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
  # ❌ No max_session_duration set - defaults to 3600 seconds (1 hour)

  tags = merge(
    var.tags,
    {
      Name        = var.role_name
      ManagedBy   = "Terraform"
      Purpose     = "EC2 Least Privilege Access"
    }
  )
}

# After (EXPLICIT SESSION DURATION)
resource "aws_iam_role" "ec2_least_privilege" {
  name                 = var.role_name
  description          = "IAM Role with least privilege access to EC2 resources"
  assume_role_policy   = data.aws_iam_policy_document.assume_role_policy.json
  max_session_duration = var.max_session_duration  # ✅ Explicitly configured

  tags = merge(
    var.tags,
    {
      Name        = var.role_name
      ManagedBy   = "Terraform"
      Purpose     = "EC2 Least Privilege Access"
    }
  )
}

# Add to variables.tf
variable "max_session_duration" {
  description = "Maximum session duration in seconds (3600-43200)"
  type        = number
  default     = 3600  # 1 hour - secure default
  
  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "Session duration must be between 3600 (1 hour) and 43200 (12 hours) seconds"
  }
}
```

**Session Duration Guidance by Use Case**:

| Use Case | Recommended Duration | Justification |
|----------|---------------------|---------------|
| Web applications | 3600s (1 hour) | Automatic credential rotation via SDK |
| Batch processing | 14400s (4 hours) | Reduces overhead for medium-length jobs |
| Data pipelines | 43200s (12 hours) | Long-running ETL processes |
| High-security workloads | 3600s (1 hour) | Minimize credential exposure window |
| Internet-facing services | 3600s (1 hour) | Reduce blast radius of compromise |

**Source**: [AWS IAM - Modifying a role maximum session duration - https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_use.html]  
**Reference**: [AWS Security Best Practices - Temporary Credentials]

**Effort**: Low (5-10 minutes to add variable and configure)

---

## Compliance Assessment

### CIS AWS Foundations Benchmark v1.5.0

| Control | Requirement | Status | Notes |
|---------|-------------|--------|-------|
| 1.16 | Ensure IAM policies with full administrative privileges are not attached | ✅ **PASS** | No wildcard `*:*` permissions |
| 1.19 | Ensure IAM instance roles are used for EC2 access to AWS resources | ✅ **PASS** | Instance profile implemented |
| 1.20 | Ensure IAM users are managed through identity federation | ✅ **PASS** | Service principal, not user-based |
| 3.1 | Ensure CloudTrail is enabled in all regions | ⚠️ **MANUAL** | Not configured in this module |
| 3.2 | Ensure CloudTrail log file validation is enabled | ⚠️ **MANUAL** | Not configured in this module |
| 3.5 | Ensure AWS Config is enabled | ⚠️ **MANUAL** | Out of scope |

**Overall CIS Compliance**: **Partial** - IAM controls pass, logging controls require separate configuration

---

### NIST 800-53 Rev. 5 Controls

| Control | Requirement | Status | Notes |
|---------|-------------|--------|-------|
| AC-2 | Account Management | ✅ **PASS** | Automated via Terraform |
| AC-3 | Access Enforcement | ⚠️ **PARTIAL** | Least privilege partially implemented (Finding 2) |
| AC-6 | Least Privilege | ⚠️ **PARTIAL** | Overly broad read permissions (Finding 2) |
| AU-2 | Audit Events | ⚠️ **MANUAL** | CloudTrail required (Finding 3) |
| AU-3 | Content of Audit Records | ⚠️ **MANUAL** | CloudTrail required (Finding 3) |
| IA-2 | Identification and Authentication | ✅ **PASS** | Service principal authentication |
| SC-12 | Cryptographic Key Management | ✅ **N/A** | No encryption keys managed |

**Overall NIST Compliance**: **Partial** - Core IAM controls pass, audit logging gap

---

### AWS Well-Architected Framework - Security Pillar

| Best Practice | Control | Status | Notes |
|---------------|---------|--------|-------|
| SEC02-BP01 | Use strong sign-in mechanisms | ✅ **PASS** | Service principal (no user credentials) |
| SEC02-BP02 | Grant least privilege access | ⚠️ **PARTIAL** | Finding 2: Overly broad read permissions |
| SEC02-BP03 | Establish emergency access | ⚠️ **REVIEW** | No break-glass access documented |
| SEC03-BP01 | Define access requirements | ✅ **PASS** | Tag-based conditions implemented |
| SEC03-BP03 | Automate provisioning | ✅ **PASS** | Terraform automation |
| SEC03-BP09 | Share resources securely with third party | ⚠️ **ISSUE** | Finding 1: External ID misconfigured |
| SEC04-BP01 | Configure service and application logging | ⚠️ **GAP** | Finding 3: CloudTrail not configured |
| SEC05-BP01 | Enforce encryption in transit | ✅ **N/A** | Not applicable (IAM role) |
| SEC05-BP02 | Enforce encryption at rest | ✅ **N/A** | Not applicable (IAM role) |

**Overall Well-Architected Score**: **7/9 applicable controls pass or partial**

---

### SOC 2 Controls

| Control | Requirement | Status | Notes |
|---------|-------------|--------|-------|
| CC6.1 | Logical and physical access controls | ✅ **PASS** | IAM role-based access |
| CC6.2 | System logging and monitoring | ❌ **GAP** | Finding 3: CloudTrail required |
| CC6.3 | Access removal when no longer authorized | ✅ **PASS** | Terraform state management |
| CC6.6 | Least privilege | ⚠️ **PARTIAL** | Finding 2: Overly broad permissions |
| CC6.7 | Encryption | ✅ **N/A** | Not applicable (IAM role) |

**Overall SOC 2 Compliance**: **Partial** - Logging gap is critical for SOC 2 audit

---

## Security Best Practices - Strengths

This configuration demonstrates several **excellent security practices**:

### ✅ 1. Tag-Based Conditional Access Control
```hcl
condition {
  test     = "StringEquals"
  variable = "ec2:ResourceTag/ManagedBy"
  values   = ["${var.role_name}"]
}
```
**Why This Is Good**: Implements attribute-based access control (ABAC) for write operations, ensuring the role can only modify instances it manages. This prevents lateral movement and limits blast radius.

**Source**: [AWS IAM - ABAC for AWS - https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction_attribute-based-access-control.html]

---

### ✅ 2. Separation of Read and Write Permissions
The policy separates read-only operations from write operations into distinct statements with different scoping rules.

**Why This Is Good**: Follows defense-in-depth principle by applying different security controls based on operation sensitivity.

---

### ✅ 3. Input Validation on Variables
```hcl
validation {
  condition     = can(regex("^[a-zA-Z0-9+=,.@_-]+$", var.role_name))
  error_message = "Role name must contain only alphanumeric characters and +=,.@_-"
}

validation {
  condition     = length(var.external_id) >= 8
  error_message = "External ID must be at least 8 characters long"
}
```
**Why This Is Good**: Prevents injection attacks and ensures compliance with AWS IAM naming requirements. Validates security-sensitive inputs.

**Source**: [AWS IAM - IAM identifiers - https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_iam-quotas.html]

---

### ✅ 4. Resource Tagging for Governance
Consistent tagging strategy applied to all resources with `ManagedBy`, `Name`, and custom tags.

**Why This Is Good**: Enables cost allocation, compliance tracking, and automated governance policies.

**Source**: [AWS Tagging Best Practices - https://docs.aws.amazon.com/general/latest/gr/aws_tagging.html]

---

### ✅ 5. Service-Scoped Trust Policy
Trust policy limited to `ec2.amazonaws.com` service principal only.

**Why This Is Good**: Prevents unauthorized assumers. Only EC2 service can assume this role, not users or other services.

---

### ✅ 6. Limited Instance Management Actions
Write permissions restricted to `StartInstances`, `StopInstances`, `RebootInstances` - no `TerminateInstances` or `RunInstances`.

**Why This Is Good**: Prevents accidental or malicious instance deletion/creation, limiting potential damage.

---

## Recommendations Summary

### **High Priority** (Before Production)

1. **Fix External ID Trust Policy** (Finding 1) - Remove incompatible condition or add separate cross-account statement
2. **Scope Read Permissions** (Finding 2) - Replace wildcard actions with specific required actions
3. **Implement CloudTrail Logging** (Finding 3) - Enable audit logging or document prerequisites

### **Medium Priority** (Current Sprint)

4. Implement IAM permissions boundary (Finding 4)
5. Configure max session duration (Finding 5)
6. Add CloudWatch alarms for security events
7. Enable AWS IAM Access Analyzer to identify unused permissions

### **Low Priority** (Backlog)

8. Document break-glass emergency access procedures
9. Implement automated policy review using Terraform Sentinel or OPA
10. Add integration tests for role assumption
11. Create runbooks for security incident response

---

## Testing Recommendations

### Unit Tests (Terraform)

```hcl
# tests/iam_role_test.go (using Terratest)
func TestIAMRoleTrustPolicy(t *testing.T) {
  // Test that External ID condition is removed for EC2 service principal
  // Test that only ec2.amazonaws.com can assume role
}

func TestIAMPolicyPermissions(t *testing.T) {
  // Test that policy does not contain wildcard actions
  // Test that write permissions have tag-based conditions
}
```

### Integration Tests

```bash
# Test role assumption from EC2 instance
aws sts get-caller-identity --profile ec2-instance-role

# Test permissions (should succeed)
aws ec2 describe-instances --profile ec2-instance-role

# Test conditional write (should succeed for tagged instances)
aws ec2 stop-instances --instance-ids i-xxx --profile ec2-instance-role

# Test denied operation (should fail)
aws ec2 terminate-instances --instance-ids i-xxx --profile ec2-instance-role
```

### Security Validation

```bash
# IAM Access Analyzer
aws accessanalyzer create-analyzer --analyzer-name iam-role-analyzer --type ACCOUNT

# CloudTrail log analysis
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=EventName,AttributeValue=AssumeRole \
  --max-items 10

# IAM Policy Simulator
aws iam simulate-principal-policy \
  --policy-source-arn arn:aws:iam::123456789012:role/ec2-least-privilege-role \
  --action-names ec2:TerminateInstances \
  --resource-arns arn:aws:ec2:us-east-1:123456789012:instance/i-xxx
```

---

## Additional Resources

### AWS Documentation
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Security Best Practices in IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/IAMBestPracticesAndUseCases.html)
- [AWS Well-Architected Security Pillar](https://docs.aws.amazon.com/wellarchitected/latest/security-pillar/welcome.html)
- [IAM Roles for EC2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html)

### Compliance Frameworks
- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)
- [AWS Compliance Programs](https://aws.amazon.com/compliance/programs/)

### Tools
- [IAM Access Analyzer](https://aws.amazon.com/iam/features/analyze-access/)
- [AWS CloudTrail](https://aws.amazon.com/cloudtrail/)
- [terraform-compliance](https://terraform-compliance.com/)
- [Checkov](https://www.checkov.io/)
- [tfsec](https://aquasecurity.github.io/tfsec/)

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-01-14 | AWS Security Advisor | Initial security review |

**Next Review Date**: 2026-04-14 (90 days)  
**Review Frequency**: Quarterly or upon significant configuration changes

---

**END OF SECURITY REVIEW**
