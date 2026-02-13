// Metric filters on app log group: common production patterns.
// Emit custom metrics to namespace Custom/App for dashboards and alarms.
// When your app writes to this log group, these filters will count matches.

locals {
  app_log_group    = aws_cloudwatch_log_group.app.name
  metric_namespace  = "Custom/App"
  metric_value_one  = "1"
  metric_default    = "0"
}

# Application errors (literal "ERROR" in log line; many frameworks use this)
resource "aws_cloudwatch_log_metric_filter" "error_count" {
  name           = "${var.name}-error-count"
  log_group_name = local.app_log_group
  pattern        = "ERROR"

  metric_transformation {
    name          = "ErrorCount"
    namespace     = local.metric_namespace
    value         = local.metric_value_one
    default_value = local.metric_default
  }
}

# Server errors 5xx (status in log line, e.g. access log " 500 ")
resource "aws_cloudwatch_log_metric_filter" "server_error_500" {
  name           = "${var.name}-5xx-500"
  log_group_name = local.app_log_group
  pattern        = "\" 500 \""

  metric_transformation {
    name          = "ServerErrorCount"
    namespace     = local.metric_namespace
    value         = local.metric_value_one
    default_value = local.metric_default
  }
}

resource "aws_cloudwatch_log_metric_filter" "server_error_502" {
  name           = "${var.name}-5xx-502"
  log_group_name = local.app_log_group
  pattern        = "\" 502 \""

  metric_transformation {
    name          = "ServerErrorCount"
    namespace     = local.metric_namespace
    value         = local.metric_value_one
    default_value = local.metric_default
  }
}

resource "aws_cloudwatch_log_metric_filter" "server_error_503" {
  name           = "${var.name}-5xx-503"
  log_group_name = local.app_log_group
  pattern        = "\" 503 \""

  metric_transformation {
    name          = "ServerErrorCount"
    namespace     = local.metric_namespace
    value         = local.metric_value_one
    default_value = local.metric_default
  }
}

# Client errors 4xx (separate filters so each match increments ClientErrorCount)
resource "aws_cloudwatch_log_metric_filter" "client_error_400" {
  name           = "${var.name}-4xx-400"
  log_group_name = local.app_log_group
  pattern        = "\" 400 \""

  metric_transformation {
    name          = "ClientErrorCount"
    namespace     = local.metric_namespace
    value         = local.metric_value_one
    default_value = local.metric_default
  }
}

resource "aws_cloudwatch_log_metric_filter" "client_error_401" {
  name           = "${var.name}-4xx-401"
  log_group_name = local.app_log_group
  pattern        = "\" 401 \""

  metric_transformation {
    name          = "ClientErrorCount"
    namespace     = local.metric_namespace
    value         = local.metric_value_one
    default_value = local.metric_default
  }
}

resource "aws_cloudwatch_log_metric_filter" "client_error_403" {
  name           = "${var.name}-4xx-403"
  log_group_name = local.app_log_group
  pattern        = "\" 403 \""

  metric_transformation {
    name          = "ClientErrorCount"
    namespace     = local.metric_namespace
    value         = local.metric_value_one
    default_value = local.metric_default
  }
}

resource "aws_cloudwatch_log_metric_filter" "client_error_404" {
  name           = "${var.name}-4xx-404"
  log_group_name = local.app_log_group
  pattern        = "\" 404 \""

  metric_transformation {
    name          = "ClientErrorCount"
    namespace     = local.metric_namespace
    value         = local.metric_value_one
    default_value = local.metric_default
  }
}

# Timeouts
resource "aws_cloudwatch_log_metric_filter" "timeout_count" {
  name           = "${var.name}-timeout"
  log_group_name = local.app_log_group
  pattern        = "timeout"

  metric_transformation {
    name          = "TimeoutCount"
    namespace     = local.metric_namespace
    value         = local.metric_value_one
    default_value = local.metric_default
  }
}

# Auth failures (401/403 already counted in ClientErrorCount; separate metric for auth-specific alerts)
resource "aws_cloudwatch_log_metric_filter" "auth_failure_401" {
  name           = "${var.name}-auth-401"
  log_group_name = local.app_log_group
  pattern        = "\" 401 \""

  metric_transformation {
    name          = "AuthFailureCount"
    namespace     = local.metric_namespace
    value         = local.metric_value_one
    default_value = local.metric_default
  }
}

resource "aws_cloudwatch_log_metric_filter" "auth_failure_403" {
  name           = "${var.name}-auth-403"
  log_group_name = local.app_log_group
  pattern        = "\" 403 \""

  metric_transformation {
    name          = "AuthFailureCount"
    namespace     = local.metric_namespace
    value         = local.metric_value_one
    default_value = local.metric_default
  }
}

# Request count (lines that look like HTTP access log: contain "HTTP/1")
resource "aws_cloudwatch_log_metric_filter" "request_count" {
  name           = "${var.name}-request"
  log_group_name = local.app_log_group
  pattern        = "HTTP"

  metric_transformation {
    name          = "RequestCount"
    namespace     = local.metric_namespace
    value         = local.metric_value_one
    default_value = local.metric_default
  }
}
