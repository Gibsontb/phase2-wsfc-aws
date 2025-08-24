# Author: tgibson
# Date: 08/23/25

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Project    = var.project
      Env        = var.env
      Owner      = "TGibson"
      CostCenter = "Dev01"
    }
  }
}
