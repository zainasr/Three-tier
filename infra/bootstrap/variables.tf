variable "github_repo" {
  description = "GitHub repository in owner/repo format (e.g. myorg/3-tier)."
  type        = string
}

variable "aws_region" {
  description = "AWS region."
  type        = string
  default     = "ap-south-1"
}

variable "state_bucket" {
  description = "S3 bucket used for Terraform state (for policy to allow backend access)."
  type        = string
  default     = "cloud-observability-tfstate-449981399767"
}
