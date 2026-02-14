output "github_actions_role_arn" {
  description = "ARN of the IAM role to use as AWS_ROLE_ARN in GitHub Actions secrets."
  value       = aws_iam_role.github_actions.arn
}
