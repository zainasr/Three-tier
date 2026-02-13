variable "name" {
  description = "Prefix for monitoring resources."
  type        = string
}

variable "alb_arn_suffix" {
  description = "ALB ARN suffix (e.g. loadbalancer/app/name/id) for metric dimensions."
  type        = string
}

variable "target_group_arn_suffix_blue" {
  description = "Blue target group ARN suffix for UnHealthyHostCount."
  type        = string
}

variable "rds_instance_id" {
  description = "RDS instance identifier for CPU alarm."
  type        = string
  default     = ""
}

variable "alarm_email" {
  description = "Email for SNS alarm notifications (optional)."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Tags for monitoring resources."
  type        = map(string)
  default     = {}
}
