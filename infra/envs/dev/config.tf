// AWS Config: configuration recorder, delivery to S3, and common managed rules.

module "config" {
  source = "../../modules/config"

  name = "${var.project_name}-${var.environment}"

  recorder_resource_types    = [] // empty = record all supported resource types
  enable_common_managed_rules = true

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "config"
  }
}
