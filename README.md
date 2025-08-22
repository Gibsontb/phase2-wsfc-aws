<!-- Author: tgibson -->
# Phase 2 — WSFC→AWS Plan + Terraform Web Stack (Single Repo)

This repo contains:
- **docs/**: assignment brief, high-level WSFC→AWS plan (DOCX), and slide deck (PPTX)
- **scripts/**: PowerShell helper for WSFC listener/NLB probe settings
- **iac/**: Terraform stack (ALB, ASG, RDS, VPC, SGs, IAM, S3), ready to `terraform apply`

## Quick Start

1. **Set up AWS credentials** (e.g., `aws configure`), Terraform >= 1.6
2. (Optional) Create an S3 backend for state — see `iac/backend.tf.example`
3. **Run**:
   ```bash
   cd iac
   cp dev.auto.tfvars.example dev.auto.tfvars   # edit as needed
   terraform init
   terraform plan
   terraform apply -auto-approve
   ```
4. Grab the outputs:
   - `alb_dns_name`, `vpc_id`, `asg_name`, `rds_endpoint`, `s3_bucket`, `logs_bucket`

### TLS (Optional)
Provide an ACM certificate ARN (same region) and enable TLS:
```bash
terraform apply -var 'enable_tls=true' -var 'acm_certificate_arn=arn:aws:acm:...'
```
HTTP will redirect to HTTPS automatically.

### What’s Deployed
- VPC with **2 public**, **2 private app**, **2 private db** subnets
- **ALB** in public subnets (HTTP + optional **TLS** on 443, **access logs to S3**)
- **ASG** (desired=2) in private subnets, **SSM Session Manager** access (no SSH), user data boots Nginx
- **RDS PostgreSQL** in private subnets; password generated via **AWS Secrets Manager**
- **S3** artifacts bucket + **S3** logs bucket (90-day lifecycle)
- **Security Groups**: least privilege (ALB→App→DB)

### CI
Basic GitHub Actions workflow runs `terraform fmt` and `terraform validate` on push/PR.

---

## WSFC → AWS (Single-Subnet) Plan
See `docs/WSFC_to_AWS_Plan.docx` and `docs/WSFC_to_AWS_Plan.pptx` for the concise, presentation-ready plan covering:
- Preparation, networking (VPN/DX, DNS, routing), EC2/SQL build
- Extending WSFC, **quorum/witness**, **Dynamic Quorum**
- **Listener via AWS NLB** (TCP 1433) with a **custom health probe** port
- SQL AG join, testing, and a **low-downtime cutover**

**Helper script:** `scripts/wsfc_nlb_helper.ps1` to set `RegisterAllProvidersIP=0`, a low `HostRecordTTL`, and a probe port on the listener resource, with firewall rules for SQL and probe.

---

## Clean Up
```bash
cd iac
terraform destroy -auto-approve
```

> Notes: defaults aim to be cost-conscious (single NAT, t3.micro). Adjust sizes, turn on Multi-AZ, or add per-AZ NATs for full HA.


## Module layout
- `modules/vpc/` — VPC, subnets across 2 AZs, IGW, single NAT, routes
- `modules/security/` — Security Groups (ALB/App/DB) with least-privilege rules
- `modules/iam/` — EC2 role + instance profile for **SSM Session Manager** access
- `modules/asg/` — Launch Template + ASG (desired=2), health checks, user data (Nginx)
- `modules/alb/` — Application Load Balancer (HTTP, optional TLS), access logging to S3
- `modules/rds/` — PostgreSQL in private subnets; password in **Secrets Manager**
- `user_data/app.sh` — boots a simple HTTP service

## Design choices & tradeoffs
- **Private subnets** for app/DB with no public IPs; egress via **NAT** → safer than instance-level egress.
- **TLS optional**: keep 80 for simplicity; when TLS is enabled, 80 redirects → 443 at ALB; backend stays HTTP (80).
- **Engine version**: defaults to provider's latest available by omitting `engine_version`; you can pin by setting `module.rds.engine_version`.
- **Least privilege SGs**: ALB egress restricted to App SG on 80; App egress restricted to DB SG on 5432; DB ingress only from App SG.
- **Cost vs HA**: one NAT GW and t3.micro defaults keep costs low; scale up instance classes or add per-AZ NATs/Multi-AZ RDS for production HA.


---
## Optional: Organization-wide guardrails (SCPs)
In `org/` you’ll find **Terraform for AWS Organizations Service Control Policies (SCPs)** that reinforce this stack’s patterns:
- **Allowed regions only**
- **Require tags** (`Project`, `Environment`, `Owner`, `CostCenter`) at *create* time
- **No public IPs on EC2 instances** (SSM-only access model)
- **Deny open SSH/RDP (22/3389) from 0.0.0.0/0**
- **Deny RDS PubliclyAccessible=true**

> Apply these only from the **Organizations management account** (or delegated admin) and set `apply_scps=true`. By default they are **disabled**.

Quick start (management account only):
```bash
cd org
terraform init
terraform apply -var 'apply_scps=true'       -var 'allowed_regions=["us-east-1"]'       -var 'required_tag_keys=["Project","Environment","Owner","CostCenter"]'
```


## Expected output (sample)
After `terraform apply`, you should see outputs like:
```
alb_dns_name = "alb-web-1234567890.us-east-1.elb.amazonaws.com"
asg_name     = "asg-app"
rds_endpoint = "postgres-app.abc123xyz.us-east-1.rds.amazonaws.com:5432"
s3_bucket    = "phase2-web-artifacts-1a2b3c4d"
logs_bucket  = "phase2-web-logs-1a2b3c4d"
vpc_id       = "vpc-0abc1234def567890"
```
