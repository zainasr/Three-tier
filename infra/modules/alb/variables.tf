variable "name" {
  description = "Base name prefix for ALB resources (e.g. project-env)."
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC where the ALB will live."
  type        = string
}

variable "public_subnet_ids" {
  description = "Public subnet IDs in which to place the ALB."
  type        = list(string)
}

variable "allowed_ingress_cidrs" {
  description = "CIDR blocks allowed to access the ALB (e.g. 0.0.0.0/0 or office ranges)."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener."
  type        = string
}

variable "enable_waf" {
  description = "Whether to associate a WAFv2 WebACL with this ALB."
  type        = bool
  default     = false
}

variable "waf_web_acl_arn" {
  description = "ARN of the WAFv2 WebACL to associate with the ALB when enable_waf is true."
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags to apply to all resources."
  type        = map(string)
  default     = {}
}

