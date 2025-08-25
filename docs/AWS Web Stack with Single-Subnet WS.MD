AWS Web Stack with Single-Subnet WSFC Extension

Author: tgibson
Date: 08/24/25
Overview

This repository provisions a production-like AWS web stack using Terraform.
It also serves as a foundation for extending an on-prem Windows Server Failover Cluster (WSFC) and SQL Always On Availability Group (AG) into AWS using a single-subnet design.

Architecture

The Terraform modules deploy the following:

VPC (10.0.0.0/16) with DNS hostnames/resolution enabled.

Subnets:

2× Public subnets (for ALB + NAT).

2× Private App subnets (for Auto Scaling Group).

2× Private DB subnets (for RDS).

Internet Gateway + NAT Gateway for private subnet egress.

Application Load Balancer (ALB):

Public, across 2 AZs.

Listener on port 80 (TLS optional).

Access logging to S3 with lifecycle policy.

Auto Scaling Group (ASG):

EC2 instances, no public IPs.

Bootstraps Nginx via user data.

IAM Instance Profile with SSM Session Manager access.

Amazon RDS (PostgreSQL 15.4):

db.t3.micro by default.

Multi-AZ optional.

Accessible only from App SG.

S3 Buckets:

Artifacts bucket (private, versioned).

Logs bucket (for ALB access logs, lifecycle policy, proper bucket policy).

Security Groups (least privilege):

ALB SG: inbound 80/443 from world → app SG.

App SG: inbound app port from ALB SG → DB SG.

DB SG: inbound 5432 only from App SG.

iac/
├── main.tf           # Root wiring for modules
├── variables.tf      # Root input variables
├── outputs.tf        # Root outputs
├── terraform.tfvars  # Default values
├── modules/
│   ├── vpc/          # VPC, subnets, NAT, IGW
│   ├── security/     # Security groups
│   ├── alb/          # Application Load Balancer
│   ├── asg/          # Launch Template + Auto Scaling Group
│   ├── rds/          # PostgreSQL + subnet group
│   ├── iam/          # IAM role + instance profile
│   └── s3/           # Artifacts + Logs buckets
└── scripts/
└── undeploy.sh   # Helper script for destroy/cleanup



Prerequisites

Terraform v1.6+

AWS CLI configured with credentials

IAM permissions to provision VPC, EC2, RDS, ALB, IAM, and S3



From the iac directory

terraform init -upgrade
terraform plan -out=plan.out
terraform apply "plan.out"
terraform output



Outputs

vpc\_id – VPC identifier

alb\_dns\_name – ALB DNS name

asg\_name – Auto Scaling Group name

rds\_endpoint – PostgreSQL endpoint

s3\_bucket – artifacts bucket

logs\_bucket – logs bucket



Teardown

Destroy everything with the helper script:

./scripts/undeploy.sh



This will:

Run terraform destroy -auto-approve with your terraform.tfvars.

Remove local .terraform/ cache.

Delete all AWS resources created by this repo.







Design Choices \& Tradeoffs

Single-subnet AG: Required for scenario, so SQL/WSFC replicas are in one private subnet.

No public IPs: All instances are private; access via SSM Session Manager only.

NAT Gateway: Managed, reliable outbound egress for patching.

Multi-AZ RDS: Off by default for cost; can be enabled in production.

TLS optional: Default HTTP only; ACM cert support included.

Strict SGs: Enforce web → app → db pattern.

S3 lifecycle rules: Expire logs after 90 days.

