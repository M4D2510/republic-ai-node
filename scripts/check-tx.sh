#!/bin/bash
# check-tx.sh - look up a TX by hash
HASH="${1:?Usage: check-tx.sh <hash>}"
curl -s "http://localhost:43317/cosmos/tx/v1beta1/txs/$HASH" | jq
