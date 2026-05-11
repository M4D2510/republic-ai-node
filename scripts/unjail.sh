#!/bin/bash
# unjail.sh
# Send unjail TX for the Republic AI validator after downtime

set -e

KEY="${KEY:-wallet}"
CHAIN_ID="${CHAIN_ID:-raitestnet_77701-1}"
NODE="${NODE:-tcp://localhost:43657}"
GAS_PRICES="${GAS_PRICES:-2000000000arai}"
GAS="${GAS:-300000}"
VALOPER="${VALOPER:-raivaloper1cucu7k60gmqx9mflvvjhguv3pf2q42774mz0ht}"

echo "=== Unjail validator ==="
echo "Validator: $VALOPER"
echo "Chain:     $CHAIN_ID"
echo "Node:      $NODE"

# Status check first
STATUS=$(republicd q staking validator "$VALOPER" --node "$NODE" -o json | jq -r '.jailed')
echo "Currently jailed: $STATUS"

if [[ "$STATUS" != "true" ]]; then
  echo "Validator is not jailed. Nothing to do."
  exit 0
fi

echo ""
echo "Submitting unjail TX..."
republicd tx slashing unjail \
  --from "$KEY" \
  --chain-id "$CHAIN_ID" \
  --node "$NODE" \
  --gas "$GAS" \
  --gas-prices "$GAS_PRICES" \
  --broadcast-mode sync \
  --yes

echo ""
echo "Wait ~6 seconds for inclusion, then re-check:"
echo "  republicd q staking validator $VALOPER --node $NODE -o json | jq '.jailed'"
