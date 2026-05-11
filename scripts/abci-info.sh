#!/bin/bash
# abci-info.sh - ABCI app info
curl -s http://localhost:43657/abci_info | jq
