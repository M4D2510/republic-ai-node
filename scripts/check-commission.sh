#!/bin/bash
# check-commission.sh - query accumulated commission
VALOPER="${VALOPER:-raivaloper1cucu7k60gmqx9mflvvjhguv3pf2q42774mz0ht}"
curl -s "http://localhost:43317/cosmos/distribution/v1beta1/validators/$VALOPER/commission" | jq
