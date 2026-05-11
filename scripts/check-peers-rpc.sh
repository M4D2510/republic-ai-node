#!/bin/bash
# check-peers-rpc.sh - list connected p2p peers
curl -s http://localhost:43657/net_info | jq '.result.peers | length'
