#!/bin/bash
# tx-index-disable.sh - disable tx_index to save disk
CFG="$HOME/.republicd/config/config.toml"
sed -i.bak 's/^indexer = .*/indexer = "null"/' "$CFG"
echo "tx_index disabled. Restart republicd to apply."
