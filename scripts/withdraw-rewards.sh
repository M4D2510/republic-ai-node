#!/bin/bash
# withdraw-rewards.sh - claim validator rewards + commission
set -e
KEY="${KEY:-wallet}"
CHAIN_ID="${CHAIN_ID:-raitestnet_77701-1}"
NODE="${NODE:-tcp://localhost:43657}"
VALOPER="${VALOPER:-raivaloper1cucu7k60gmqx9mflvvjhguv3pf2q42774mz0ht}"
echo "Withdrawing rewards + commission for $VALOPER..."
republicd tx distribution withdraw-rewards "$VALOPER" \
  --commission \
  --from "$KEY" \
  --chain-id "$CHAIN_ID" \
  --node "$NODE" \
  --gas 400000 \
  --gas-prices 2000000000arai \
  --yes
