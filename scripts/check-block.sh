#!/bin/bash
# check-block.sh - inspect a specific block
H="${1:-latest}"
curl -s "http://localhost:43657/block?height=$H" | jq '.result.block.header'
