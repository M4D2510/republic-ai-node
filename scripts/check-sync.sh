#!/bin/bash
# check-sync.sh - simple sync status check
curl -s http://localhost:43657/status | jq '.result.sync_info'
