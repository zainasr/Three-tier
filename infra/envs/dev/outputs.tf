// Surface key networking outputs so other stacks (ALB, app, DB) can consume them.

output "vpc_id" {
  description = "ID of the shared VPC."
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs for ALB and NAT gateways."
  value       = module.vpc.public_subnet_ids
}

output "private_app_subnet_ids" {
  description = "Private app subnet IDs for the EC2 app tier."
  value       = module.vpc.private_app_subnet_ids
}

output "private_db_subnet_ids" {
  description = "Private DB subnet IDs for RDS."
  value       = module.vpc.private_db_subnet_ids
}

output "rds_endpoint" {
  description = "RDS instance endpoint (host:port)."
  value       = module.rds.endpoint
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret containing DB credentials."
  value       = aws_secretsmanager_secret.db.arn
}

output "cloudwatch_dashboard" {
  description = "CloudWatch dashboard name."
  value       = module.monitoring.dashboard_name
}

output "alarm_sns_topic_arn" {
  description = "SNS topic for alarm notifications."
  value       = module.monitoring.alarm_sns_topic_arn
}

