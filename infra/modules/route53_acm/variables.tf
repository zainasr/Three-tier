variable "domain_name" {
  description = "Primary domain name for the certificate and hosted zone (e.g. example.com)."
  type        = string
}

variable "subject_alternative_names" {
  description = "Additional domain names (SANs) for the ACM certificate."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Common tags to apply to Route 53 and ACM resources."
  type        = map(string)
  default     = {}
}

