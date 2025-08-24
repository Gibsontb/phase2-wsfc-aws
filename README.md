# Author: tgibson
# Date: 08/24/25

# Phase 2 — WSFC Stretch Plan + AWS Web Stack (Terraform)

This repo contains **two deliverables, plus a scripts utility**:

1. **Design Scenario — Extend on‑prem WSFC/SQL AG to AWS (single subnet, VNN + NLB, no DNN)**  
   Files in `docs/`:
   - `WSFC_to_AWS_Plan.docx` — concise bullet plan
   - `WSFC_to_AWS_ShortDeck.pptx` — short slide deck for IT/DB walkthrough

2. **Infrastructure‑as‑Code — Minimal AWS web stack (Terraform)**  
   Code in `iac/` with clean modules and a README (`docs/AWS_WebStack_README.md`) that explains setup.

## Quick start for Terraform
cd iac
terraform init
terraform apply plan.out
```

### Key outputs
Outputs:
alb_dns_name = "alb-web-361150572.us-east-1.elb.amazonaws.com"
asg_name = "asg"
logs_bucket = "phase2-web-logs-4hrxjq"
rds_endpoint = "pg-db.cgpm0cqsihgx.us-east-1.rds.amazonaws.com"
s3_bucket = "phase2-web-artifacts-4hrxjq"
vpc_id = "vpc-0ca1b3c9483438d0e"

> Design choices: private app/DB, SSM over SSH, NAT egress, ALB access logs to S3, optional TLS at ALB.


3. **Scripts Utility** destroy.ps1, To be run in the iac directory with powershell. It will completely destroy all infrastructure deployed.