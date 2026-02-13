// RDS PostgreSQL in private DB subnets; only app tier can connect.

resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnet"
  subnet_ids = var.db_subnet_ids

  tags = merge(
    { Name = "${var.name}-db-subnet" },
    var.tags,
  )
}

resource "aws_security_group" "db" {
  name        = "${var.name}-db-sg"
  description = "Allow app tier to connect to RDS"
  vpc_id      = var.vpc_id

  ingress {
    description     = "PostgreSQL from app"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = var.app_security_group_ids
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    { Name = "${var.name}-db-sg" },
    var.tags,
  )
}

resource "aws_db_instance" "this" {
  identifier     = "${var.name}-db"
  engine         = "postgres"
  engine_version = "16"

  instance_class    = var.instance_class
  allocated_storage = var.allocated_storage

  db_name  = var.db_name
  username = var.username
  password = var.password

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.db.id]
  publicly_accessible    = false
  multi_az               = var.multi_az

  storage_encrypted = true
  skip_final_snapshot = var.skip_final_snapshot

  tags = merge(
    { Name = "${var.name}-db" },
    var.tags,
  )
}
