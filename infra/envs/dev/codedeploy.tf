// CodeDeploy blue/green deployment group: shifts ALB traffic from blue to green (and back) during deployments.

module "codedeploy" {
  source = "../../modules/codedeploy"

  name = "${var.project_name}-${var.environment}"

  target_group_blue_name  = module.alb.target_group_blue_name
  target_group_green_name = module.alb.target_group_green_name

  instance_tag_key   = "Project"
  instance_tag_value = var.project_name

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "codedeploy"
  }

  depends_on = [module.alb]
}
