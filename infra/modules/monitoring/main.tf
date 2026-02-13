// CloudWatch log groups, alarms, and a simple dashboard.

resource "aws_cloudwatch_log_group" "app" {
  name              = "/${var.name}/app"
  retention_in_days = 14

  tags = var.tags
}

resource "aws_sns_topic" "alarms" {
  name = "${var.name}-alarms"

  tags = var.tags
}

resource "aws_sns_topic_subscription" "alarm_email" {
  count = var.alarm_email != "" ? 1 : 0

  topic_arn = aws_sns_topic.alarms.arn
  protocol  = "email"
  endpoint   = var.alarm_email
}

# ALB 5xx alarm
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name          = "${var.name}-alb-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 5

  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  tags          = var.tags
}

# Unhealthy hosts (blue target group)
resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${var.name}-unhealthy-hosts"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0

  dimensions = {
    TargetGroup  = var.target_group_arn_suffix_blue
    LoadBalancer = var.alb_arn_suffix
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  tags          = var.tags
}

# RDS CPU (optional)
resource "aws_cloudwatch_metric_alarm" "rds_cpu" {
  count = var.rds_instance_id != "" ? 1 : 0

  alarm_name          = "${var.name}-rds-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods   = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    DBInstanceIdentifier = var.rds_instance_id
  }

  alarm_actions = [aws_sns_topic.alarms.arn]
  tags          = var.tags
}

# App error count from log metric filter (custom metric)
resource "aws_cloudwatch_metric_alarm" "app_errors" {
  alarm_name          = "${var.name}-app-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ErrorCount"
  namespace           = "Custom/App"
  period              = 60
  statistic           = "Sum"
  threshold           = 10

  alarm_actions = [aws_sns_topic.alarms.arn]
  tags          = var.tags
}

# App server errors 5xx from log metric filter
resource "aws_cloudwatch_metric_alarm" "app_server_errors" {
  alarm_name          = "${var.name}-app-5xx"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ServerErrorCount"
  namespace           = "Custom/App"
  period              = 60
  statistic           = "Sum"
  threshold           = 5

  alarm_actions = [aws_sns_topic.alarms.arn]
  tags          = var.tags
}

data "aws_region" "current" {}

locals {
  base_widgets = [
    {
      type   = "metric"
      x      = 0
      y      = 0
      width  = 12
      height = 6
      properties = {
        title  = "ALB Request count"
        region = data.aws_region.current.name
        metrics = [
          ["AWS/ApplicationELB", "RequestCount", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum", period = 60 }]
        ]
      }
    },
    {
      type   = "metric"
      x      = 12
      y      = 0
      width  = 12
      height = 6
      properties = {
        title  = "ALB 5xx"
        region = data.aws_region.current.name
        metrics = [
          ["AWS/ApplicationELB", "HTTPCode_ELB_5XX_Count", "LoadBalancer", var.alb_arn_suffix, { stat = "Sum", period = 60 }]
        ]
      }
    },
    {
      type   = "metric"
      x      = 0
      y      = 6
      width  = 12
      height = 6
      properties = {
        title  = "ALB Target response time"
        region = data.aws_region.current.name
        metrics = [
          ["AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", var.alb_arn_suffix, { stat = "Average", period = 60 }]
        ]
      }
    },
    {
      type   = "metric"
      x      = 12
      y      = 6
      width  = 12
      height = 6
      properties = {
        title  = "UnHealthy host count (blue)"
        region = data.aws_region.current.name
        metrics = [
          ["AWS/ApplicationELB", "UnHealthyHostCount", "TargetGroup", var.target_group_arn_suffix_blue, "LoadBalancer", var.alb_arn_suffix, { stat = "Average", period = 60 }]
        ]
      }
    }
  ]
  rds_widget = var.rds_instance_id != "" ? [{
    type   = "metric"
    x      = 0
    y      = 12
    width  = 12
    height = 6
    properties = {
      title  = "RDS CPU"
      region = data.aws_region.current.name
      metrics = [
        ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", var.rds_instance_id, { stat = "Average", period = 300 }]
      ]
    }
  }] : []

  # Custom metrics from app log filters (namespace Custom/App)
  custom_metric_namespace = "Custom/App"
  custom_widgets = [
    {
      type   = "metric"
      x      = 0
      y      = 18
      width  = 8
      height = 6
      properties = {
        title  = "App ErrorCount (from logs)"
        region = data.aws_region.current.name
        metrics = [
          [local.custom_metric_namespace, "ErrorCount", { stat = "Sum", period = 60 }]
        ]
      }
    },
    {
      type   = "metric"
      x      = 8
      y      = 18
      width  = 8
      height = 6
      properties = {
        title  = "App ServerErrorCount 5xx (from logs)"
        region = data.aws_region.current.name
        metrics = [
          [local.custom_metric_namespace, "ServerErrorCount", { stat = "Sum", period = 60 }]
        ]
      }
    },
    {
      type   = "metric"
      x      = 16
      y      = 18
      width  = 8
      height = 6
      properties = {
        title  = "App ClientErrorCount 4xx (from logs)"
        region = data.aws_region.current.name
        metrics = [
          [local.custom_metric_namespace, "ClientErrorCount", { stat = "Sum", period = 60 }]
        ]
      }
    },
    {
      type   = "metric"
      x      = 0
      y      = 24
      width  = 8
      height = 6
      properties = {
        title  = "App TimeoutCount (from logs)"
        region = data.aws_region.current.name
        metrics = [
          [local.custom_metric_namespace, "TimeoutCount", { stat = "Sum", period = 60 }]
        ]
      }
    },
    {
      type   = "metric"
      x      = 8
      y      = 24
      width  = 8
      height = 6
      properties = {
        title  = "App AuthFailureCount (from logs)"
        region = data.aws_region.current.name
        metrics = [
          [local.custom_metric_namespace, "AuthFailureCount", { stat = "Sum", period = 60 }]
        ]
      }
    },
    {
      type   = "metric"
      x      = 16
      y      = 24
      width  = 8
      height = 6
      properties = {
        title  = "App RequestCount (from logs)"
        region = data.aws_region.current.name
        metrics = [
          [local.custom_metric_namespace, "RequestCount", { stat = "Sum", period = 60 }]
        ]
      }
    }
  ]
  dashboard_widgets = concat(local.base_widgets, local.rds_widget, local.custom_widgets)
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = var.name

  dashboard_body = jsonencode({
    widgets = local.dashboard_widgets
  })
}
