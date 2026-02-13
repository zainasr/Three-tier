
terraform {
  backend "s3" {
    bucket = "cloud-observability-tfstate-449981399767"
    key    = "envs/dev/terraform.tfstate"
    region = "ap-south-1"
    encrypt = true
  }
}

