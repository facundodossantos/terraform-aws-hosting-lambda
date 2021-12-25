### Providers
terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.40"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

locals {
  default_resource_prefix = replace(local.main_domain, "/[^a-zA-Z0-9_-]/", "_")
}
