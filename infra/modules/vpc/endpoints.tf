// VPC endpoints for private access to common AWS services from app subnets.
// This reduces round trips over the public internet and fits zero‑trust
// principles by keeping traffic inside the AWS network where possible.

data "aws_region" "current" {}

// Security group for interface endpoints: allow HTTPS from inside the VPC.
resource "aws_security_group" "vpc_endpoints" {
  name        = "${var.name}-vpce-sg"
  description = "Allow HTTPS from within the VPC to interface endpoints"
  vpc_id      = aws_vpc.this.id

  ingress {
    description = "HTTPS from VPC CIDR"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    {
      Name = "${var.name}-vpce-sg"
    },
    var.tags,
  )
}

// Gateway endpoint for S3: attaches to private route tables so S3 traffic
// from private subnets stays within the AWS network.
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.s3"
  vpc_endpoint_type = "Gateway"

  // Attach to app and DB private route tables; public subnets typically
  // use the internet gateway directly.
  route_table_ids = concat(
    [for rt in aws_route_table.private_app : rt.id],
    [for rt in aws_route_table.private_db  : rt.id],
  )

  tags = merge(
    {
      Name = "${var.name}-s3-endpoint"
    },
    var.tags,
  )
}

// Interface endpoints live in private subnets and expose AWS APIs via
// private IPs. We place them in app subnets since workloads there need
// access to these services.

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ecr.api"
  vpc_endpoint_type = "Interface"

  subnet_ids         = [for s in aws_subnet.private_app : s.id]
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  private_dns_enabled = true

  tags = merge(
    {
      Name = "${var.name}-ecr-api-endpoint"
    },
    var.tags,
  )
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ecr.dkr"
  vpc_endpoint_type = "Interface"

  subnet_ids         = [for s in aws_subnet.private_app : s.id]
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  private_dns_enabled = true

  tags = merge(
    {
      Name = "${var.name}-ecr-dkr-endpoint"
    },
    var.tags,
  )
}

resource "aws_vpc_endpoint" "logs" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.logs"
  vpc_endpoint_type = "Interface"

  subnet_ids         = [for s in aws_subnet.private_app : s.id]
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  private_dns_enabled = true

  tags = merge(
    {
      Name = "${var.name}-logs-endpoint"
    },
    var.tags,
  )
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ssm"
  vpc_endpoint_type = "Interface"

  subnet_ids         = [for s in aws_subnet.private_app : s.id]
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  private_dns_enabled = true

  tags = merge(
    {
      Name = "${var.name}-ssm-endpoint"
    },
    var.tags,
  )
}

resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  vpc_endpoint_type = "Interface"

  subnet_ids         = [for s in aws_subnet.private_app : s.id]
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  private_dns_enabled = true

  tags = merge(
    {
      Name = "${var.name}-ssmmessages-endpoint"
    },
    var.tags,
  )
}

resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.name}.ec2messages"
  vpc_endpoint_type = "Interface"

  subnet_ids         = [for s in aws_subnet.private_app : s.id]
  security_group_ids = [aws_security_group.vpc_endpoints.id]

  private_dns_enabled = true

  tags = merge(
    {
      Name = "${var.name}-ec2messages-endpoint"
    },
    var.tags,
  )
}

