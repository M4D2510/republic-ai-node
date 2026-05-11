#!/bin/bash
# check-signing.sh - signing info for our validator
curl -s "http://localhost:43317/cosmos/slashing/v1beta1/signing_infos" | jq '.info[] | select(.address | contains("'${CONS_ADDR:-}'"))'
