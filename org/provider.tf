# Author: tgibson
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
# Organizations APIs are global; any region works (use same region as your accounts for consistency)
provider "aws" {
  region = var.org_region
}
