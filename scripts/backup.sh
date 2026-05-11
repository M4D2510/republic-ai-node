#!/bin/bash
# backup.sh
# Backup critical validator state to a timestamped tar.gz

set -e

HOME_DIR="${HOME_DIR:-$HOME/.republicd}"
BACKUP_DIR="${BACKUP_DIR:-/root/validator-backups}"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
OUTPUT="$BACKUP_DIR/validator-state-$TIMESTAMP.tar.gz"

mkdir -p "$BACKUP_DIR"

echo "=== Validator state backup ==="
echo "Source: $HOME_DIR"
echo "Output: $OUTPUT"
echo ""

# Critical files only - never the full data dir (multi-GB)
tar czf "$OUTPUT" -C "$HOME_DIR" \
  config/priv_validator_key.json \
  config/node_key.json \
  config/genesis.json \
  data/priv_validator_state.json \
  2>/dev/null

SIZE=$(du -h "$OUTPUT" | cut -f1)
echo "Backup created: $OUTPUT ($SIZE)"

echo ""
echo "Retain last 10 backups, remove older:"
ls -t "$BACKUP_DIR"/validator-state-*.tar.gz | tail -n +11 | xargs -r rm -v

echo ""
echo "=== Done ==="
echo "Restore with:"
echo "  tar xzf $OUTPUT -C \$HOME/.republicd/"
