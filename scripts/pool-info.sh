#!/bin/bash
# pool-info.sh - staking pool stats
curl -s http://localhost:43317/cosmos/staking/v1beta1/pool | jq
