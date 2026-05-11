#!/bin/bash
# consensus-state.sh - dump current consensus state
curl -s http://localhost:43657/consensus_state | jq '.result.round_state'
