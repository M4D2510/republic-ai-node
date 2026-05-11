#!/bin/bash
# check-params.sh - staking params
curl -s "http://localhost:43317/cosmos/staking/v1beta1/params" | jq
