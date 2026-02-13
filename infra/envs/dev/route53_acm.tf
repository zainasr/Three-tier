// Route 53 hosted zone + ACM certificate for imdb-review.me.
// This creates:
// - A public hosted zone in Route 53
// - An ACM certificate validated via DNS records in that hosted zone
// After apply, take the `name_servers` output from this module and configure
// them as the NS for imdb-review.me in Namecheap.

module "route53_acm" {
  source = "../../modules/route53_acm"

  domain_name = "imdbreview.me"
  subject_alternative_names = [
    "www.imdbreview.me",
  ]

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "dns-acm"
  }
}

// Apex A record: empty name means record is the zone root (imdbreview.me).
resource "aws_route53_record" "root_alb" {
  zone_id = module.route53_acm.zone_id
  name    = ""
  type    = "A"

  alias {
    name                   = module.alb.alb_dns_name
    zone_id                = module.alb.alb_zone_id
    evaluate_target_health = true
  }

  depends_on = [
    module.route53_acm,
    module.alb,
  ]
}

