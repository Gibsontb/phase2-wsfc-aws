#!/bin/bash
# Author: tgibson
set -xe
apt-get update -y
apt-get install -y nginx
systemctl enable nginx
cat > /var/www/html/index.html <<'HTML'
<html><body><h1>It works 🎉</h1><p>Instance $(hostname)</p></body></html>
HTML
