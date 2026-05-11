#!/bin/bash
# export-genesis.sh - export current chain state as genesis
H="${1:-0}"
republicd export --height "$H" --home "$HOME/.republicd" > "/tmp/genesis-export-$H.json"
echo "Exported to /tmp/genesis-export-$H.json"
