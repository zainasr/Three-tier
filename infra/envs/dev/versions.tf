// Central Terraform and provider version constraints for the dev environment.
// Keeping this in one place is a common 2026 best practice so all modules
// inherit consistent versions.

terraform {
  required_version = "~> 1.14.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.32.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

