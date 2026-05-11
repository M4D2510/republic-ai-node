#!/bin/bash
# check-version.sh - report installed vs latest republicd version
set -e
INSTALLED=$(republicd version 2>&1 | head -1)
LATEST=$(curl -s "https://api.github.com/repos/dyphira-git/republic-protocol/releases/latest" 2>/dev/null | jq -r '.tag_name // "unknown"')
echo "Installed: $INSTALLED"
echo "Latest:    $LATEST"
[ "$INSTALLED" != "$LATEST" ] && echo "UPDATE AVAILABLE" || echo "Up to date"
