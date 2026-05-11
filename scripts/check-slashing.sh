#!/bin/bash
# check-slashing.sh - slashing params
curl -s "http://localhost:43317/cosmos/slashing/v1beta1/params" | jq
