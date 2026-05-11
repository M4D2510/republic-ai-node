#!/bin/bash
# account-info.sh - on-chain account info
ADDR="${1:?Usage: account-info.sh <address>}"
curl -s "http://localhost:43317/cosmos/auth/v1beta1/accounts/$ADDR" | jq
