#!/bin/bash
# check-balance.sh - query wallet balance
ADDR="${1:?Usage: check-balance.sh <address>}"
curl -s "http://localhost:43317/cosmos/bank/v1beta1/balances/$ADDR" | jq
