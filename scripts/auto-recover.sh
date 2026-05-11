#!/bin/bash
# auto-recover.sh - automated validator recovery orchestrator
# 
# Sequence:
#   1. Check if jailed
#   2. If jailed, verify node is synced
#   3. If synced, submit unjail TX
#   4. Verify bonded status post-TX
#   5. Report final state
#
# Designed to be cron-safe: exits early if not jailed,
# only acts when intervention is needed.

set -euo pipefail

VALOPER="${VALOPER:-raivaloper1cucu7k60gmqx9mflvvjhguv3pf2q42774mz0ht}"
NODE="${NODE:-tcp://localhost:43657}"
REST="${REST:-http://localhost:43317}"
KEY="${KEY:-wallet}"
CHAIN_ID="${CHAIN_ID:-raitestnet_77701-1}"
LOG="${LOG:-/var/log/auto-recover.log}"

log() { echo "[$(date '+%F %T')] $*" | tee -a "$LOG"; }

# Step 1: jail check
JAILED=$(curl -sf "$REST/cosmos/staking/v1beta1/validators/$VALOPER" \
  | jq -r '.validator.jailed // "unknown"')
log "Jailed status: $JAILED"

if [ "$JAILED" != "true" ]; then
  log "Not jailed, exiting"
  exit 0
fi

# Step 2: sync check
CATCHING=$(curl -sf "${NODE#tcp://}/status" \
  | jq -r '.result.sync_info.catching_up // "unknown"')
log "Catching up: $CATCHING"

if [ "$CATCHING" = "true" ]; then
  log "Still syncing, skip unjail attempt"
  exit 0
fi

# Step 3: unjail TX
log "Submitting unjail TX..."
republicd tx slashing unjail \
  --from "$KEY" \
  --chain-id "$CHAIN_ID" \
  --node "$NODE" \
  --gas 300000 \
  --gas-prices 2000000000arai \
  --broadcast-mode sync \
  --yes 2>&1 | tee -a "$LOG"

sleep 8

# Step 4: verify
NEW_STATUS=$(curl -sf "$REST/cosmos/staking/v1beta1/validators/$VALOPER" \
  | jq -r '.validator.status')
log "Post-unjail status: $NEW_STATUS"

if [ "$NEW_STATUS" = "BOND_STATUS_BONDED" ]; then
  log "Recovery successful"
else
  log "WARN: status is $NEW_STATUS, manual review needed"
fi
