
# Minimal AWS Web Stack (Terraform) — README

This repository deploys a production-ish, **private-by-default** web stack in AWS using Terraform.

## What it creates
- **VPC** with subnets across 2 AZs
  - **2× public** (for ALB)
  - **1× private** (for app + database) — or toggle to **2× private app** subnets in vars for HA
- **NAT Gateway** for private egress (OS/package updates)
- **Security Groups** (least privilege)
  - **ALB SG**: inbound 80 (world), egress to App SG
  - **App SG**: inbound from ALB SG on app port (default 80), egress to DB SG:5432
  - **DB SG**: inbound 5432 from App SG only
- **ALB (public)** on port 80
  - Target group = ASG instances
  - (Optional) access logs to **S3** with lifecycle
- **Auto Scaling Group (Linux)** with Launch Template
  - Desired capacity **2** in **private** subnet(s)
  - **No public IPs**; access via **SSM Session Manager**
  - User data bootstraps a simple HTTP service (Nginx) and health endpoint
- **PostgreSQL (Amazon RDS)** in private subnet(s)
  - Latest engine by default
  - Multi‑AZ **optional** (see variable `rds_multi_az`)
  - SG restricts access to App SG
- **S3 bucket** for logs/artifacts
  - Block public access; versioning enabled
- **Consistent tags**: `Project`, `Env`, `Owner`, `CostCenter`
- **Outputs**: ALB DNS name, VPC ID, ASG name, RDS endpoint, S3 bucket name

## Prerequisites
- Terraform >= **1.6**
- AWS credentials with permissions for VPC/EC2/ALB/ASG/IAM/RDS/S3/SSM
- (Optional) AWS CLI configured for your account

## How to run
```bash
cd iac
terraform init
terraform plan -var='env=dev' -var='project=phase2' -out=plan.out
terraform apply plan.out
```

### Common variables (examples)
```bash
terraform plan   -var='env=dev'   -var='region=us-east-1'   -var='vpc_cidr=10.20.0.0/16'   -var='public_subnet_cidrs=["10.20.0.0/24","10.20.1.0/24"]'   -var='private_subnet_cidrs=["10.20.100.0/24"]'   -var='instance_type=t3.small'   -var='asg_desired=2' -var='asg_min=2' -var='asg_max=4'   -var='app_port=80'   -var='rds_engine_version=latest'   -var='rds_multi_az=false'   -var='db_username=appuser' -var='db_password=ChangeMe123!'   -var='tags={"Project":"Phase2","Env":"dev","Owner":"tgibson","CostCenter":"1234"}'
```

> Credentials: Use **SSM Parameter Store / Secrets Manager** for DB creds in real environments. No hard‑coded secrets in code.

## Module layout
- `modules/vpc` — VPC, subnets, NAT, route tables, IGW
- `modules/security` — security groups for ALB/App/DB
- `modules/alb` — ALB, target group, listener (80), (optional) access logs to S3
- `modules/asg` — Launch Template (SSM role), ASG, user data (Nginx)
- `modules/rds` — PostgreSQL RDS (private), parameter group
- `modules/iam` — SSM Instance Profile / IAM roles
- `modules/s3` — S3 bucket for logs/artifacts (public access blocked, versioning on)

## Expected outputs
- `alb_dns_name` — public endpoint to hit the app
- `vpc_id` — deployed VPC
- `asg_name` — name of the Auto Scaling Group
- `rds_endpoint` — PostgreSQL endpoint (private)
- `s3_bucket_name` — bucket used for logs/artifacts

## Design choices & tradeoffs
- **Private app/DB**: minimizes exposure; ALB is the only public surface.
- **SSM over SSH**: no inbound 22; Session Manager for access.
- **NAT Gateway**: simple, managed egress; instance‑level egress is possible but higher ops overhead.
- **TLS optional**: for the exercise we keep HTTP on ALB; in prod, terminate TLS at ALB with ACM certs.
- **Multi‑AZ DB optional**: cost vs. HA. Toggle per environment.

## CI suggestion (optional)
Add a basic check:
```bash
terraform fmt -recursive
terraform validate
```
