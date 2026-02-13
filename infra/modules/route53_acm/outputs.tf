output "zone_id" {
  description = "ID of the Route 53 hosted zone."
  value       = aws_route53_zone.this.zone_id
}

output "name_servers" {
  description = "Name server records for the hosted zone (add these at the registrar)."
  value       = aws_route53_zone.this.name_servers
}

output "certificate_arn" {
  description = "ARN of the validated ACM certificate."
  value       = aws_acm_certificate.this.arn
}

