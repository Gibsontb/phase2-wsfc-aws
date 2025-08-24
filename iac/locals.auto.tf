# Author: tgibson
# Date: 08/24/25

locals {
  common_tags = {
    Project    = var.project
    Env        = var.env
    Owner      = "TGibson"
    CostCenter = "Dev01"
  }
}
