variable "name" {
  description = "Prefix for WAF WebACL and rules."
  type        = string
}

variable "rate_limit" {
  description = "Max requests per 5 minutes per IP (rate-based rule)."
  type        = number
  default     = 2000
}

variable "tags" {
  description = "Tags for WAF resources."
  type        = map(string)
  default     = {}
}
