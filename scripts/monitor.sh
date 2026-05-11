#!/bin/bash
# monitor.sh
# Continuous block height monitor with stall detection

set -e

NODE="${NODE:-http://localhost:43657}"
INTERVAL="${INTERVAL:-30}"
STALL_THRESHOLD="${STALL_THRESHOLD:-3}"

echo "=== Block height monitor ==="
echo "Node:     $NODE"
echo "Interval: ${INTERVAL}s"
echo "Stall threshold: ${STALL_THRESHOLD} consecutive checks"
echo ""

PREV_HEIGHT=0
STALL_COUNT=0

while true; do
  HEIGHT=$(curl -s "$NODE/status" 2>/dev/null \
    | jq -r '.result.sync_info.latest_block_height // "ERROR"')
  CATCHING=$(curl -s "$NODE/status" 2>/dev/null \
    | jq -r '.result.sync_info.catching_up // "?"')
  TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

  if [[ "$HEIGHT" == "ERROR" ]]; then
    echo "[$TIMESTAMP] RPC unreachable"
  elif [[ "$HEIGHT" == "$PREV_HEIGHT" ]]; then
    STALL_COUNT=$((STALL_COUNT + 1))
    echo "[$TIMESTAMP] height=$HEIGHT (STALLED x$STALL_COUNT) catching_up=$CATCHING"
    if [[ "$STALL_COUNT" -ge "$STALL_THRESHOLD" ]]; then
      echo "[$TIMESTAMP] !!! ALERT: block production stalled !!!"
    fi
  else
    DIFF=$((HEIGHT - PREV_HEIGHT))
    echo "[$TIMESTAMP] height=$HEIGHT (+$DIFF) catching_up=$CATCHING"
    STALL_COUNT=0
  fi

  PREV_HEIGHT=$HEIGHT
  sleep "$INTERVAL"
done
