#!/bin/bash
# delegate.sh - delegate stake to a validator
set -e
KEY="${KEY:-wallet}"
CHAIN_ID="${CHAIN_ID:-raitestnet_77701-1}"
NODE="${NODE:-tcp://localhost:43657}"
VALOPER="${1:?Usage: delegate.sh <valoper> <amount_arai>}"
AMOUNT="${2:?Usage: delegate.sh <valoper> <amount_arai>}"
echo "Delegating $AMOUNT arai to $VALOPER..."
republicd tx staking delegate "$VALOPER" "${AMOUNT}arai" \
  --from "$KEY" \
  --chain-id "$CHAIN_ID" \
  --node "$NODE" \
  --gas 300000 \
  --gas-prices 2000000000arai \
  --yes
