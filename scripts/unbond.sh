#!/bin/bash
# unbond.sh - unbond stake from a validator
VAL="${1:?Usage: unbond.sh <valoper> <amount_arai>}"
AMT="${2:?}"
republicd tx staking unbond "$VAL" "${AMT}arai" --from wallet --chain-id raitestnet_77701-1 --gas 300000 --gas-prices 2000000000arai --yes
