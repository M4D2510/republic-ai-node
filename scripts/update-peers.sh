#!/bin/bash
# update-peers.sh
# Refresh persistent_peers in Republic node config from a curated peer list

set -e

CONFIG="${CONFIG:-$HOME/.republicd/config/config.toml}"

# AWS canonical peers (M4D2510 infrastructure)
PEERS=$(cat <<'PEERLIST' | tr '\n' ',' | sed 's/,$//'
1fc361b76cb5d3190027e18299a22e3dcb689dd9@32.195.95.92:26656
a840530175d59707309fe00bb6eb0369459e5127@54.163.45.48:26656
cd10f1a4162e3a4fadd6993a24fd5a32b27b8974@54.243.22.128:26656
f13fec7efb7538f517c74435e082c7ee54b4a0ff@54.204.89.111:26656
PEERLIST
)

echo "=== Updating persistent_peers ==="
echo "Config: $CONFIG"
echo "Peer count: $(echo "$PEERS" | tr ',' '\n' | wc -l)"

cp "$CONFIG" "$CONFIG.bak.$(date +%s)"
sed -i "s|^persistent_peers *=.*|persistent_peers = \"$PEERS\"|" "$CONFIG"

echo ""
echo "Updated. Restart republicd for changes to take effect:"
echo "  systemctl restart republicd"
