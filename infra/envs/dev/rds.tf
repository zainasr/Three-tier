// RDS PostgreSQL in private DB subnets; app tier can connect via security group.

resource "random_password" "db" {
  length  = 24
  special = true
}

module "rds" {
  source = "../../modules/rds"

  name       = "${var.project_name}-${var.environment}"
  vpc_id     = module.vpc.vpc_id
  db_subnet_ids = module.vpc.private_db_subnet_ids
  app_security_group_ids = [module.app_blue.security_group_id, module.app_green.security_group_id]

  instance_class    = "db.t3.micro"
  allocated_storage = 20
  db_name           = "app"
  username          = "appadmin"
  password          = random_password.db.result

  multi_az             = false
  skip_final_snapshot  = true

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "rds"
  }

  depends_on = [module.app_blue, module.app_green]
}

// Store DB connection secret for app to use (e.g. via IAM + Secrets Manager).
resource "aws_secretsmanager_secret" "db" {
  name = "${var.project_name}/${var.environment}/db"

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id     = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    host     = module.rds.address
    port     = tostring(module.rds.port)
    dbname   = module.rds.db_name
    username = "appadmin"
    password = random_password.db.result
  })
}

# IAM policy: allow app instances to read the DB secret (for /db and DB connection).
resource "aws_iam_policy" "app_db_secret" {
  name        = "${var.project_name}-${var.environment}-app-db-secret"
  description = "Allow app tier to read DB connection secret"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "secretsmanager:GetSecretValue"
        Resource = aws_secretsmanager_secret.db.arn
      }
    ]
  })
}
