#!/bin/bash
# genesis-info.sh - chain-id and genesis time
curl -s http://localhost:43657/genesis | jq '.result.genesis | {chain_id, genesis_time}'
