#!/bin/bash
# validator-health-check.sh
# Republic AI validator quick health check
# Reports sync status, jailed state, and block height

set -e

RPC="${RPC:-tcp://localhost:43657}"
REST="${REST:-http://localhost:43317}"
VALOPER="${VALOPER:-raivaloper1cucu7k60gmqx9mflvvjhguv3pf2q42774mz0ht}"

echo "=== Republic AI Validator Health Check ==="
echo "RPC: $RPC"
echo "REST: $REST"
echo ""

echo "--- Sync status ---"
curl -s "${RPC#tcp://}/status" 2>/dev/null \
  | jq '.result.sync_info | {height: .latest_block_height, catching_up}'

echo ""
echo "--- Validator status ---"
curl -s "$REST/cosmos/staking/v1beta1/validators/$VALOPER" \
  | jq '.validator | {moniker: .description.moniker, status, jailed, tokens}'

echo ""
echo "--- Signing window ---"
CONSADDR=$(curl -s "$REST/cosmos/staking/v1beta1/validators/$VALOPER" \
  | jq -r '.validator.consensus_pubkey.key')
echo "Consensus pubkey: $CONSADDR"

echo ""
echo "=== Done ==="
