#!/bin/bash
# check-supply.sh - total chain supply
curl -s "http://localhost:43317/cosmos/bank/v1beta1/supply" | jq
