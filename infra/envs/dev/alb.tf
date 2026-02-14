locals {
  alb_name = "${var.project_name}-${var.environment}"
}

module "alb" {
  source = "../../modules/alb"

  name              = local.alb_name
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids

  allowed_ingress_cidrs = ["0.0.0.0/0"]

  certificate_arn = module.route53_acm.certificate_arn

  enable_waf      = true
  waf_web_acl_arn = module.waf.web_acl_arn

  tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Component   = "alb"
  }

  
  depends_on = [module.route53_acm, module.waf]
}

