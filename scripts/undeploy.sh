# Author: tgibson
# Date: 08/23/25

#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/undeploy.sh [tfvars_file]
# Defaults to terraform.tfvars in the current directory.

TFVARS_FILE="${1:-terraform.tfvars}"

echo ">> terraform init (upgrade providers/modules)"
terraform init -upgrade

echo ">> terraform destroy using ${TFVARS_FILE}"
terraform destroy -auto-approve -var-file="${TFVARS_FILE}"

echo ">> Local cleanup (state remains if you use a remote backend)"
rm -rf .terraform/ || true
echo "Done."


terraform destroy -auto-approve -var-file="${TFVARS_FILE}"


