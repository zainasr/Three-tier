
data "aws_region" "current" {}

resource "aws_security_group" "app" {
  name        = "${var.name}-app-sg"
  description = "Security group for app instances"
  vpc_id      = var.vpc_id

  // Allow HTTP from the ALB only.
  ingress {
    description = "App traffic from ALB"
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    security_groups = [
      var.alb_security_group_id,
    ]
  }

  // Outbound: allow access to VPC endpoints, RDS, etc.
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name = "${var.name}-app-sg"
    },
    var.tags,
  )
}

resource "aws_iam_role" "app" {
  name = "${var.name}-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

// Minimalist policy: allow pulling from ECR, publishing logs, and SSM Session Manager.
resource "aws_iam_policy" "app" {
  name = "${var.name}-app-policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EcrRead"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      },
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "*"
      },
      {
        Sid    = "SSMCore"
        Effect = "Allow"
        Action = [
          "ssm:DescribeAssociation",
          "ssm:GetDeployablePatchSnapshotForInstance",
          "ssm:GetDocument",
          "ssm:DescribeDocument",
          "ssm:GetManifest",
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:ListAssociations",
          "ssm:ListInstanceAssociations",
          "ssm:PutInventory",
          "ssm:PutComplianceItems",
          "ssm:PutConfigurePackageResult",
          "ssm:UpdateAssociationStatus",
          "ssm:UpdateInstanceAssociationStatus",
          "ssm:UpdateInstanceInformation",
          "ssmmessages:CreateControlChannel",
          "ssmmessages:CreateDataChannel",
          "ssmmessages:OpenControlChannel",
          "ssmmessages:OpenDataChannel",
          "ec2messages:AcknowledgeMessage",
          "ec2messages:DeleteMessage",
          "ec2messages:FailMessage",
          "ec2messages:GetEndpoint",
          "ec2messages:GetMessages",
          "ec2messages:SendReply"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "app" {
  role       = aws_iam_role.app.name
  policy_arn = aws_iam_policy.app.arn
}

resource "aws_iam_role_policy_attachment" "additional" {
  for_each = toset(var.additional_policy_arns)

  role       = aws_iam_role.app.name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "app" {
  name = "${var.name}-app-instance-profile"
  role = aws_iam_role.app.name
}

locals {
  # ECR registry host (no path) for docker login
  ecr_registry = regex("^[^/]+", var.ecr_repository_url)
  # Build docker run -e args from container_env; value is shell-escaped (wrap in single quotes for safety).
  container_env_args = join(" ", [for k, v in var.container_env : "-e '${k}=${replace(v, "'", "'\"'\"'")}'"])

  user_data_nginx = <<-EOT
              #!/bin/bash
              set -euo pipefail
              dnf update -y
              dnf install -y nginx amazon-ssm-agent
              systemctl enable nginx amazon-ssm-agent
              systemctl start nginx amazon-ssm-agent
              cat > /etc/nginx/conf.d/health.conf <<'NGINX'
              location /health { default_type application/json; return 200 '{"status":"ok"}'; }
              NGINX
              nginx -t && systemctl reload nginx
              echo "User data (nginx) completed at $(date)" >> /var/log/user-data.log
              EOT

  user_data_app = <<-EOT
              #!/bin/bash
              set -euo pipefail
              dnf update -y
              dnf install -y docker amazon-ssm-agent
              systemctl enable docker amazon-ssm-agent
              systemctl start docker amazon-ssm-agent
              aws ecr get-login-password --region ${data.aws_region.current.name} \
                | docker login --username AWS --password-stdin ${local.ecr_registry}
              docker pull ${var.ecr_repository_url}:${var.image_tag}
              docker run -d --name app --restart unless-stopped \
                -p ${var.container_port}:${var.container_port} \
                ${local.container_env_args} \
                ${var.ecr_repository_url}:${var.image_tag}
              echo "User data (app container) completed at $(date)" >> /var/log/user-data.log
              EOT

  user_data = var.use_app_container ? local.user_data_app : local.user_data_nginx
}

resource "aws_launch_template" "app" {
  name_prefix   = "${var.name}-lt-"
  image_id      = var.image_id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.app.name
  }

  vpc_security_group_ids = [aws_security_group.app.id]

  user_data = base64encode(local.user_data)

  update_default_version = true

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      {
        Name = "${var.name}-app"
      },
      var.tags,
    )
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name                      = "${var.name}-asg"
  vpc_zone_identifier       = var.subnet_ids
  desired_capacity          = var.desired_capacity
  min_size                  = var.min_size
  max_size                  = var.max_size
  health_check_type         = "EC2"
  health_check_grace_period = 60

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  // Don't wait for target group health - just create instances and move on
  wait_for_capacity_timeout = "0"

  target_group_arns = [var.target_group_arn]

  tag {
    key                 = "Name"
    value               = "${var.name}-app"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

