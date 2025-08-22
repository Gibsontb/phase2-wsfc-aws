# Author: tgibson
variable "apply_scps" {
  description = "Master switch: apply SCPs when true (use per-policy toggles below to choose which)."
  type        = bool
  default     = false
}

variable "org_region" {
  description = "Region used by the AWS provider (Organizations is global)."
  type        = string
  default     = "us-east-1"
}

variable "target_id" {
  description = "Organizations target to attach policies to (Root or OU ID). Leave blank to auto-detect Root."
  type        = string
  default     = ""
}

variable "allowed_regions" {
  description = "Regions allowed for API calls (others are denied when the regions policy is enabled)."
  type        = list(string)
  default     = ["us-east-1"]
}

variable "required_tag_keys" {
  description = "Tag keys that must be present at resource CREATE time (when the require-tags policy is enabled)."
  type        = list(string)
  default     = ["Project", "Environment", "Owner", "CostCenter"]
}

# Per-policy toggles (all optional)
variable "enable_deny_not_allowed_regions" {
  description = "Deny API calls in regions not listed in allowed_regions."
  type        = bool
  default     = false
}

variable "enable_require_tags" {
  description = "Require request tags (Project/Environment/Owner/CostCenter) on create for key services."
  type        = bool
  default     = false
}

variable "enable_deny_public_ip_instances" {
  description = "Deny EC2 RunInstances when AssociatePublicIpAddress would be true."
  type        = bool
  default     = false
}

variable "enable_deny_open_ssh_rdp" {
  description = "Deny adding SG ingress rules that open 22/3389 to 0.0.0.0/0."
  type        = bool
  default     = false
}

variable "enable_deny_rds_public" {
  description = "Deny creating/modifying RDS instances to be publicly accessible."
  type        = bool
  default     = false
}
