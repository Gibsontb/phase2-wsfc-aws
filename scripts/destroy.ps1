# Author: tgibson
# Date: 08/23/25

# scripts/undeploy.ps1
# Removes the Terraform stack from the current directory (or a provided working dir)
# Usage examples:
#   .\scripts\undeploy.ps1                       # uses ./terraform.tfvars if present
#   .\scripts\undeploy.ps1 -Tfvars .\dev.tfvars
#   .\scripts\undeploy.ps1 -WorkingDir .\iac

[CmdletBinding()]
param(
  # Path to your tfvars file (optional). If it doesn't exist, the script continues without it.
  [string]$Tfvars = "terraform.tfvars",
  # Directory containing Terraform code/state. Defaults to current dir.
  [string]$WorkingDir = ".",
  # Optional Terraform workspace to select/create before destroy.
  [string]$Workspace = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Ensure-Command {
  param([string]$Name)
  try { Get-Command $Name -ErrorAction Stop | Out-Null }
  catch { throw "Required command '$Name' not found in PATH." }
}

Write-Host ">> Switching to working directory: $WorkingDir"
Set-Location -Path $WorkingDir

Ensure-Command -Name "terraform"
terraform -version | Out-Null

# Determine whether we'll pass -var-file
$varFileArg = @()
if (Test-Path -Path $Tfvars) {
  Write-Host ">> Using tfvars file: $Tfvars"
  $varFileArg = @("-var-file=$Tfvars")
} else {
  Write-Warning "Variables file '$Tfvars' not found. Continuing without -var-file."
}

# Init (upgrade providers/modules)
Write-Host ">> terraform init (upgrade providers/modules)"
terraform init -upgrade

# Optional workspace handling
if ($Workspace -ne "") {
  Write-Host ">> Selecting workspace: $Workspace"
  terraform workspace select $Workspace 2>$null
  if ($LASTEXITCODE -ne 0) {
    Write-Host ">> Workspace not found; creating: $Workspace"
    terraform workspace new $Workspace
  }
}

# Destroy
Write-Host ">> terraform destroy (auto-approve) ..."
terraform destroy -auto-approve @varFileArg

# Local cleanup (state remains if remote backend)
Write-Host ">> Local cleanup of .terraform/ (state file is untouched unless remote backend)"
Remove-Item -Recurse -Force ".terraform" -ErrorAction SilentlyContinue

Write-Host "Done."
