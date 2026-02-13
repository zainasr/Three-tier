// Input variables for the dev environment. These are environment-specific
// knobs; shared logic stays in modules.

variable "project_name" {
  description = "Short name of the project, used for tagging and naming."
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. dev, stage, prod)."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "az_count" {
  description = "Number of availability zones to use."
  type        = number
  default     = 2
}

variable "alarm_email" {
  description = ""
  type = string
}

