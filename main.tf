### Providers
terraform {
  required_version = ">= 1.4"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }
}

locals {
  default_resource_prefix = replace(local.main_domain, "/[^a-zA-Z0-9_-]/", "_")
}
