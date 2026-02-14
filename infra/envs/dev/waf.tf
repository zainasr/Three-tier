# WAF WebACL for ALB: AWS managed rules + rate limit.

module "waf" {
  source = "../../modules/waf"

  name       = "${var.project_name}-${var.environment}"
  rate_limit = 2000

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "waf"
  }
}
