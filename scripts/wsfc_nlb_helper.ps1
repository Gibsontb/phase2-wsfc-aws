# Author: tgibson
# WSFC + SQL AG Listener (single subnet) — helper steps
# Run in elevated PowerShell on a cluster node

# Variables (edit these)
$ClusterName = (Get-Cluster).Name
$AgListenerResourceName = "AG-Listener"        # Replace with your listener resource name
$ProbePort = 59999                              # Custom probe port for NLB health check
$SqlTcpPort = 1433

Write-Host "Setting RegisterAllProvidersIP=0 and HostRecordTTL=20 on cluster network name..."

# Find the Network Name resource for the listener (VNN) and set DNS behavior
Get-ClusterResource -Name $AgListenerResourceName | Set-ClusterParameter -Name RegisterAllProvidersIP -Value 0
Get-ClusterResource -Name $AgListenerResourceName | Set-ClusterParameter -Name HostRecordTTL -Value 20

Write-Host "Configuring cluster probe port for NLB health checks..."

# Set the probe port so only the primary answers the health probe
Get-ClusterResource -Name $AgListenerResourceName | Set-ClusterParameter -Name ProbePort -Value $ProbePort

Write-Host "Excluding probe port from use by other services..."
netsh int ipv4 add excludedportrange tcp startport=$ProbePort numberofports=1 store=persistent

Write-Host "Opening Windows Firewall for SQL and probe port (limit to NLB source SG/CIDRs as appropriate)..."
New-NetFirewallRule -DisplayName "SQL-AG-Inbound-1433" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $SqlTcpPort
New-NetFirewallRule -DisplayName "SQL-AG-Inbound-Probe" -Direction Inbound -Action Allow -Protocol TCP -LocalPort $ProbePort

Write-Host "Done. Ensure your AWS NLB target group uses TCP health check on port $ProbePort and forwards client traffic on $SqlTcpPort."
