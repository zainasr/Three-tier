// CloudTrail for API audit logging (single region, log file validation, S3 storage).

module "cloudtrail" {
  source = "../../modules/cloudtrail"

  name = "${var.project_name}-${var.environment}"

  enable_log_file_validation    = true
  include_global_service_events  = true
  is_multi_region_trail          = false

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "cloudtrail"
  }
}
