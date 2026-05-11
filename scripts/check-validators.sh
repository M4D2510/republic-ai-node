#!/bin/bash
# check-validators.sh - count active validators
curl -s "http://localhost:43317/cosmos/staking/v1beta1/validators?status=BOND_STATUS_BONDED&pagination.limit=200" | jq '.validators | length'
