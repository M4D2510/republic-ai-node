#!/bin/bash
# keys-list.sh - list keyring entries
republicd keys list --output json | jq
