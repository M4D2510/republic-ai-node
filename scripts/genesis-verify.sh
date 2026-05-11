#!/bin/bash
# genesis-verify.sh - check genesis.json sha256 against a known good value
set -e
GENESIS="${GENESIS:-$HOME/.republicd/config/genesis.json}"
EXPECTED="${EXPECTED_SHA256:?Set EXPECTED_SHA256 to the canonical hash}"
ACTUAL=$(sha256sum "$GENESIS" | awk '{print $1}')
echo "Expected: $EXPECTED"
echo "Actual:   $ACTUAL"
[ "$ACTUAL" = "$EXPECTED" ] && echo "OK: genesis matches" || { echo "MISMATCH"; exit 1; }
