// CloudWatch log group, alarms (ALB 5xx, unhealthy hosts, RDS CPU), and dashboard.

module "monitoring" {
  source = "../../modules/monitoring"

  name = "${var.project_name}-${var.environment}"

  alb_arn_suffix             = module.alb.alb_arn_suffix
  target_group_arn_suffix_blue = module.alb.target_group_blue_arn_suffix
  rds_instance_id            = module.rds.id

  alarm_email = "${var.alarm_email}"

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "monitoring"
  }

  depends_on = [module.alb, module.rds]
}
