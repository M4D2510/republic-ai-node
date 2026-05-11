#!/bin/bash
# send.sh - send tokens
TO="${1:?Usage: send.sh <to_addr> <amount_arai>}"
AMT="${2:?}"
republicd tx bank send wallet "$TO" "${AMT}arai" --chain-id raitestnet_77701-1 --gas 200000 --gas-prices 2000000000arai --yes
