# IAM Policy Document for EC2 assume role
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"
    
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    
    actions = ["sts:AssumeRole"]
  }
}

# IAM Policy Document for EC2 least privilege access
data "aws_iam_policy_document" "ec2_least_privilege" {
  statement {
    sid    = "EC2ReadOnlyAccess"
    effect = "Allow"
    
    actions = [
      "ec2:Describe*",
      "ec2:Get*",
      "ec2:List*"
    ]
    
    resources = ["*"]
  }
}

# IAM Role
resource "aws_iam_role" "ec2_least_privilege" {
  name               = var.role_name
  description        = var.role_description
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  
  tags = var.tags
}

# IAM Role Policy
resource "aws_iam_role_policy" "ec2_least_privilege" {
  name   = "${var.role_name}-policy"
  role   = aws_iam_role.ec2_least_privilege.id
  policy = data.aws_iam_policy_document.ec2_least_privilege.json
}
