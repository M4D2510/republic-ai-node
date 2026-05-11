#!/bin/bash
# snapshot-download.sh - fetch a chain snapshot for fast bootstrap
set -e
SNAPSHOT_URL="${SNAPSHOT_URL:?Set SNAPSHOT_URL to a published snapshot tarball}"
HOME_DIR="${HOME_DIR:-$HOME/.republicd}"
echo "Stopping republicd..."
systemctl stop republicd 2>/dev/null || true
echo "Backing up current data dir..."
mv "$HOME_DIR/data" "$HOME_DIR/data.bak.$(date +%s)" 2>/dev/null || true
echo "Downloading + extracting snapshot..."
curl -L "$SNAPSHOT_URL" | tar -xzf - -C "$HOME_DIR"
echo "Done. Start with: systemctl start republicd"
