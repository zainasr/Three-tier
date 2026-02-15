// Application Auto Scaling Groups (blue/green) for the dev environment.
// Each ASG:
// - Runs EC2 instances in private app subnets
// - Pulls a Docker image from ECR
// - Is attached to either the blue or green ALB target group

// AMI ID now comes from data.aws_ssm_parameter.al2023_x86_64 defined in ami.tf

module "app_blue" {
  source = "../../modules/app_asg"

  name                  = "${var.project_name}-${var.environment}-blue"
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.private_app_subnet_ids
  alb_security_group_id = module.alb.alb_security_group_id
  target_group_arn      = module.alb.target_group_blue_arn

  instance_type = "t3a.micro"

  desired_capacity = 2
  min_size         = 2
  max_size         = 4

  image_id           = local.app_image_id
  ecr_repository_url = aws_ecr_repository.app.repository_url
  image_tag          = "latest"
  container_port     = 80

  use_app_container = true
  container_env = {
    DB_SECRET_ARN = aws_secretsmanager_secret.db.arn
    AWS_REGION    = "ap-south-1"
    ENVIRONMENT   = var.environment
  }

  additional_policy_arns = { "db-secret" = aws_iam_policy.app_db_secret.arn }

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "app-blue"
  }

  depends_on = [
    module.vpc,
    module.alb,
    aws_ecr_repository.app,
    aws_iam_policy.app_db_secret,
  ]
}

module "app_green" {
  source = "../../modules/app_asg"

  name                  = "${var.project_name}-${var.environment}-green"
  vpc_id                = module.vpc.vpc_id
  subnet_ids            = module.vpc.private_app_subnet_ids
  alb_security_group_id = module.alb.alb_security_group_id
  target_group_arn      = module.alb.target_group_green_arn

  instance_type = "t3a.micro"

  desired_capacity = 0
  min_size         = 0
  max_size         = 4

  image_id           = local.app_image_id
  ecr_repository_url = aws_ecr_repository.app.repository_url
  image_tag          = "latest"
  container_port     = 80

  use_app_container = true
  container_env = {
    DB_SECRET_ARN = aws_secretsmanager_secret.db.arn
    AWS_REGION    = "ap-south-1"
    ENVIRONMENT   = var.environment
  }

  additional_policy_arns = { "db-secret" = aws_iam_policy.app_db_secret.arn }

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "app-green"
  }

  depends_on = [
    module.vpc,
    module.alb,
    aws_ecr_repository.app,
    aws_iam_policy.app_db_secret,
  ]
}

