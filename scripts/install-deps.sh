#!/bin/bash
# install-deps.sh - install host dependencies for a Republic AI validator
set -e
echo "Installing base packages..."
apt-get update -y
apt-get install -y curl wget jq git build-essential ufw fail2ban tmux htop ncdu
echo "Installing Go (1.22)..."
GO_VERSION="1.22.0"
ARCH=$(dpkg --print-architecture)
[ "$ARCH" = "amd64" ] && GO_ARCH="amd64" || GO_ARCH="arm64"
wget -q "https://go.dev/dl/go${GO_VERSION}.linux-${GO_ARCH}.tar.gz" -O /tmp/go.tar.gz
rm -rf /usr/local/go && tar -C /usr/local -xzf /tmp/go.tar.gz
echo "export PATH=\$PATH:/usr/local/go/bin" >> /root/.bashrc
echo "Done. source ~/.bashrc"
