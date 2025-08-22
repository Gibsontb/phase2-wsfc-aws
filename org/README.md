<!-- Author: tgibson -->
# AWS Organizations Guardrails (SCPs)

This optional Terraform project applies **Service Control Policies (SCPs)** to your **Root** or a specific **OU**.
> Run from the **Organizations management account** (or delegated admin) only.

## Policies included
- **DenyNotAllowedRegions** — only allow the regions you specify.
- **RequireRequestTags** — enforce tags at create time (Project, Environment, Owner, CostCenter).
- **DenyInstancesWithPublicIP** — blocks EC2 instances with public IPs (SSM-only pattern).
- **DenyOpenSshRdp** — blocks SG ingress 22/3389 from 0.0.0.0/0.
- **DenyRdsPubliclyAccessible** — prevents creating/setting public RDS instances.

## Quick start
```bash
cp org.auto.tfvars.example org.auto.tfvars   # edit as needed
terraform init
terraform apply
```
By default `apply_scps=false`. Flip it to `true` in your tfvars to actually attach the policies.

## Targeting an OU instead of the Root
Set `target_id = "ou-xxxx-..."` in your tfvars. If left blank, the Root is auto-detected.


## Policy toggles
Each SCP is optional and can be enabled independently:
- `enable_deny_not_allowed_regions`
- `enable_require_tags`
- `enable_deny_public_ip_instances`
- `enable_deny_open_ssh_rdp`
- `enable_deny_rds_public`

Remember: `apply_scps=true` must also be set, otherwise nothing is attached.
