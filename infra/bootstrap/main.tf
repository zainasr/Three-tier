# GitHub OIDC provider and IAM role for GitHub Actions (Terraform + ECR push).

data "aws_caller_identity" "current" {}

# GitHub OIDC provider (one per account)
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

# Trust policy: only your repo can assume this role
data "aws_iam_policy_document" "github_trust" {
  statement {
    effect = "Allow"
    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }
    actions = ["sts:AssumeRoleWithWebIdentity"]
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_repo}:*"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "github-actions-3tier"
  assume_role_policy = data.aws_iam_policy_document.github_trust.json
}

# Allow Terraform: S3 state + typical resources (EC2, RDS, IAM, ECR, Route53, ACM, WAF, CloudWatch, etc.)
data "aws_iam_policy_document" "github_actions" {
  statement {
    sid    = "S3State"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.state_bucket}",
      "arn:aws:s3:::${var.state_bucket}/*"
    ]
  }
  statement {
    sid    = "TerraformResources"
    effect = "Allow"
    actions = [
      "ec2:*",
      "elasticloadbalancing:*",
      "autoscaling:*",
      "rds:*",
      "iam:*",
      "secretsmanager:*",
      "route53:*",
      "acm:*",
      "wafv2:*",
      "logs:*",
      "cloudwatch:*",
      "ecr:*",
      "ssm:*",
      "s3:*"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_actions" {
  name   = "github-actions-policy"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions.json
}
