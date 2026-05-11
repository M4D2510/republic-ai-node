#!/bin/bash
# feegrant-list.sh - list active feegrants
ADDR="${1:?Usage: feegrant-list.sh <grantee>}"
curl -s "http://localhost:43317/cosmos/feegrant/v1beta1/allowances/$ADDR" | jq
