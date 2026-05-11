#!/bin/bash
# check-delegations.sh - list delegations to a validator
VALOPER="${VALOPER:-raivaloper1cucu7k60gmqx9mflvvjhguv3pf2q42774mz0ht}"
curl -s "http://localhost:43317/cosmos/staking/v1beta1/validators/$VALOPER/delegations?pagination.limit=500" | jq '.delegation_responses | length'
