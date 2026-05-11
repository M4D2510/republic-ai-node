#!/bin/bash
# state-sync.sh
# Configure Republic AI node for state sync from a trusted RPC

set -e

CONFIG="${CONFIG:-$HOME/.republicd/config/config.toml}"
RPC_SERVERS="${RPC_SERVERS:-http://54.243.22.128:26657,http://54.204.89.111:26657}"
TRUST_HEIGHT_OFFSET="${TRUST_HEIGHT_OFFSET:-2000}"

echo "=== Configuring state sync ==="
echo "Config: $CONFIG"
echo "RPC servers: $RPC_SERVERS"

# Get latest height + hash from first RPC
PRIMARY_RPC=$(echo "$RPC_SERVERS" | cut -d',' -f1)
LATEST_HEIGHT=$(curl -s "$PRIMARY_RPC/block" | jq -r '.result.block.header.height')
TRUST_HEIGHT=$((LATEST_HEIGHT - TRUST_HEIGHT_OFFSET))
TRUST_HASH=$(curl -s "$PRIMARY_RPC/block?height=$TRUST_HEIGHT" | jq -r '.result.block_id.hash')

echo "Latest height: $LATEST_HEIGHT"
echo "Trust height:  $TRUST_HEIGHT"
echo "Trust hash:    $TRUST_HASH"

cp "$CONFIG" "$CONFIG.bak.$(date +%s)"

sed -i.tmp "/^\[statesync\]/,/^\[/ {
  s|^enable *=.*|enable = true|
  s|^rpc_servers *=.*|rpc_servers = \"$RPC_SERVERS\"|
  s|^trust_height *=.*|trust_height = $TRUST_HEIGHT|
  s|^trust_hash *=.*|trust_hash = \"$TRUST_HASH\"|
  s|^trust_period *=.*|trust_period = \"168h0m0s\"|
}" "$CONFIG"
rm -f "$CONFIG.tmp"

echo ""
echo "Done. Reset state and restart:"
echo "  republicd tendermint unsafe-reset-all --home \$HOME/.republicd --keep-addr-book"
echo "  systemctl restart republicd"
