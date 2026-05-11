#!/bin/bash
# peer-test.sh - probe peer reachability over Tendermint p2p
set -e
PEERS=(
  "32.195.95.92:26656"
  "54.163.45.48:26656"
  "54.243.22.128:26656"
  "54.204.89.111:26656"
)
echo "Probing peer reachability..."
for p in "${PEERS[@]}"; do
  host="${p%:*}"; port="${p#*:}"
  timeout 3 bash -c "</dev/tcp/$host/$port" 2>/dev/null \
    && echo "  OK   $p" \
    || echo "  FAIL $p"
done
