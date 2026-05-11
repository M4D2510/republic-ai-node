#!/bin/bash
# redelegate.sh - redelegate stake between validators
SRC="${1:?Usage: redelegate.sh <src_valoper> <dst_valoper> <amount_arai>}"
DST="${2:?}"
AMT="${3:?}"
republicd tx staking redelegate "$SRC" "$DST" "${AMT}arai" --from wallet --chain-id raitestnet_77701-1 --gas 350000 --gas-prices 2000000000arai --yes
