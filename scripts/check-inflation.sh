#!/bin/bash
# check-inflation.sh - current inflation rate
curl -s "http://localhost:43317/cosmos/mint/v1beta1/inflation" | jq
