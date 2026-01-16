# IAM Role with Least Privilege EC2 Access

resource "aws_iam_role" "ec2_least_privilege" {
  name               = var.role_name
  description        = var.role_description
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = var.tags
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "ec2_least_privilege" {
  name        = "${var.role_name}-policy"
  description = "Least privilege policy for EC2 operations"
  policy      = data.aws_iam_policy_document.ec2_least_privilege.json

  tags = var.tags
}

data "aws_iam_policy_document" "ec2_least_privilege" {
  statement {
    sid    = "EC2ReadOnly"
    effect = "Allow"

    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeTags",
      "ec2:DescribeVolumes",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeVpcs"
    ]

    resources = ["*"]
  }

  dynamic "statement" {
    for_each = var.enable_instance_management ? [1] : []

    content {
      sid    = "EC2InstanceManagement"
      effect = "Allow"

      actions = [
        "ec2:StartInstances",
        "ec2:StopInstances",
        "ec2:RebootInstances"
      ]

      resources = var.ec2_resource_arns
    }
  }

  dynamic "statement" {
    for_each = var.enable_tag_management ? [1] : []

    content {
      sid    = "EC2TagManagement"
      effect = "Allow"

      actions = [
        "ec2:CreateTags",
        "ec2:DeleteTags"
      ]

      resources = var.ec2_resource_arns
    }
  }
}

resource "aws_iam_role_policy_attachment" "ec2_least_privilege" {
  role       = aws_iam_role.ec2_least_privilege.name
  policy_arn = aws_iam_policy.ec2_least_privilege.arn
}

resource "aws_iam_instance_profile" "ec2_least_privilege" {
  count = var.create_instance_profile ? 1 : 0

  name = "${var.role_name}-profile"
  role = aws_iam_role.ec2_least_privilege.name

  tags = var.tags
}
