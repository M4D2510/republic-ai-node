#!/bin/bash
# =============================================================================
# fast-auto.sh — Republic AI Compute Job Submission Script
# =============================================================================
# Author: M4D2510
# Repo:   github.com/M4D2510/republic-ai-node
#
# This script automatically submits compute jobs on the Republic AI testnet,
# runs inference, and submits results back to the chain.
#
# QUICK START:
#   1. Fill in your values in the REQUIRED section below
#   2. chmod +x fast-auto.sh
#   3. nohup ./fast-auto.sh > /root/fast-auto.log 2>&1 &
#
# MONITOR:
#   tail -f /root/fast-auto.log
#   cat /root/fast-auto-stats.log
#
# STOP:
#   pkill -f fast-auto.sh
#
# CHECK PERFORMANCE:
#   grep -c "result submitted" /root/fast-auto.log   # completed jobs
#   grep -c "not found" /root/fast-auto.log          # skipped jobs
#
# =============================================================================
# REQUIRED — REPLACE WITH YOUR OWN VALUES
# =============================================================================

# Your validator operator address (starts with raivaloper1...)
VALOPER="raivaloper1XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# Your wallet address (starts with rai1...)
WALLET="rai1XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX"

# Your wallet keyring password
PASSWORD="your_wallet_password_here"

# Your server endpoint — Cloudflare tunnel domain OR IP:PORT
# The file server (file-server.py) must be running on port 8080
# Examples:
#   Cloudflare tunnel: api.yourdomain.com
#   Direct IP:         123.456.789.0:8080
SERVER_IP="api.yourdomain.com"

# =============================================================================
# FIXED SETTINGS — do not change
# =============================================================================

NODE="tcp://localhost:43657"
CHAIN_ID="raitestnet_77701-1"
JOBS_DIR="/var/lib/republic/jobs"
JOB_FEE="1000000000000000arai"

# =============================================================================
# PERFORMANCE TUNING
# =============================================================================
#
# HOW IT WORKS:
#   1. Script broadcasts a submit-job TX to the chain
#   2. Waits TX_WAIT_SLEEP seconds for the TX to be indexed
#   3. Queries REST API to get the job ID from the TX events
#   4. If job ID not found, retries RETRY_COUNT times with RETRY_SLEEP delay
#   5. Runs inference and submits the result
#
# WHY DO SKIPS HAPPEN?
#   - The TX is broadcast but the REST API hasn't indexed it yet
#   - The TX dropped from mempool (chain-side issue, not fixable)
#   - Increasing sleep times reduces skips from indexing delays
#
# HOW TO REDUCE SKIPS:
#   Step 1: Increase TX_WAIT_SLEEP from 6 to 8 or 10
#   Step 2: If still skipping, increase RETRY_COUNT from 3 to 5
#   Step 3: If still skipping, increase RETRY_SLEEP from 3 to 5
#   Note: ~30-40% skip rate is normal due to chain mempool drops
#
# SPEED vs RELIABILITY TRADEOFF:
#
#   MODE       TX_WAIT  RETRY_COUNT  RETRY_SLEEP  RESULT  EST. JOBS/HR
#   -----------------------------------------------------------------------
#   Fast       4        3            2            1       ~400 (more skips)
#   Balanced   6        3            3            2       ~300 (recommended)
#   Safe       10       5            5            2       ~180 (fewer skips)
#   Very Safe  15       5            5            3       ~120 (min skips)
#
# RECOMMENDED: Start with Balanced, switch to Safe if skip rate > 50%

# Seconds to wait after TX broadcast before querying job ID
# Too low = more skips | Too high = slower
TX_WAIT_SLEEP=6

# How many times to retry if job ID not found
# Increase this if you see many "Job ID not found" messages
RETRY_COUNT=3

# Seconds to wait between retries
RETRY_SLEEP=3

# Seconds to wait after submitting a result
RESULT_SLEEP=2

# =============================================================================
# STATISTICS TRACKING
# =============================================================================

STATS_COMPLETED=0
STATS_SKIPPED=0
STATS_START=$(date +%s)
STATS_LAST_LOG=$(date +%s)
STATS_FILE="/root/fast-auto-stats.log"

log_stats() {
  local now=$(date +%s)
  local elapsed=$(( (now - STATS_START) / 60 ))
  local total=$((STATS_COMPLETED + STATS_SKIPPED))
  local rate=0
  [ $total -gt 0 ] && rate=$((STATS_COMPLETED * 100 / total))
  local hourly=0
  [ $elapsed -gt 0 ] && hourly=$((STATS_COMPLETED * 60 / elapsed))
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${elapsed}m | Completed:$STATS_COMPLETED | Skipped:$STATS_SKIPPED | Rate:${rate}% | ${hourly}/hr" | tee -a "$STATS_FILE"
}

# =============================================================================
# PRE-FLIGHT CHECKS
# =============================================================================

echo "🚀 Fast Auto started..."
echo "   Validator: $VALOPER"
echo "   Wallet:    $WALLET"
echo "   Server:    https://$SERVER_IP"
echo "   Node:      $NODE"
echo ""
echo "   Settings:"
echo "   TX_WAIT_SLEEP=$TX_WAIT_SLEEP | RETRY_COUNT=$RETRY_COUNT | RETRY_SLEEP=$RETRY_SLEEP"
echo ""

# Check inference server
if ! curl -s http://localhost:5555/health > /dev/null 2>&1; then
  echo "⚠️  Warning: Inference server may not be running on port 5555"
  echo "   Check: docker ps | grep inference"
fi

# Check file server
if ! curl -s https://$SERVER_IP/result > /dev/null 2>&1; then
  echo "⚠️  Warning: File server may not be reachable at $SERVER_IP"
  echo "   Check: ps aux | grep file-server"
fi

# Get initial sequence from chain
SEQ=$(republicd query auth account $WALLET --node $NODE -o json 2>/dev/null | jq -r '.account.value.sequence // .account.sequence // "0"')
echo "Starting sequence: $SEQ"
log_stats
echo ""

# =============================================================================
# MAIN LOOP
# =============================================================================

while true; do
  # Log stats every hour
  NOW=$(date +%s)
  [ $((NOW - STATS_LAST_LOG)) -ge 3600 ] && { log_stats; STATS_LAST_LOG=$NOW; }

  # -----------------------------------------------------------------------
  # STEP 1: Submit a new job to the chain
  # -----------------------------------------------------------------------
  echo "📤 Submitting new job... (seq: $SEQ)"
  TX=$(echo "$PASSWORD" | republicd tx computevalidation submit-job \
    $VALOPER \
    republic-llm-inference:latest \
    https://$SERVER_IP/upload \
    https://$SERVER_IP/result \
    example-verification:latest \
    $JOB_FEE \
    --from wallet \
    --home $HOME/.republicd \
    --chain-id $CHAIN_ID \
    --gas 300000 \
    --gas-prices 2000000000arai \
    --sequence $SEQ \
    --node $NODE \
    -y | grep txhash | awk '{print $2}')
  echo "✅ TX: $TX"

  # Wait for TX to be indexed by REST API
  # If you see too many skips → increase TX_WAIT_SLEEP
  sleep $TX_WAIT_SLEEP

  # -----------------------------------------------------------------------
  # STEP 2: Parse job ID from TX events via REST API
  # -----------------------------------------------------------------------
  JOB_ID=""
  for i in $(seq 1 $RETRY_COUNT); do
    RESPONSE=$(curl -s "https://rest.republicai.io/cosmos/tx/v1beta1/txs/$TX" 2>/dev/null)
    JOB_ID=$(echo "$RESPONSE" | jq -r '.tx_response.events[] | select(.type=="job_submitted") | .attributes[] | select(.key=="job_id") | .value' 2>/dev/null)
    [ -n "$JOB_ID" ] && break
    # TX not indexed yet, wait and retry
    # If this message appears often → increase RETRY_COUNT or RETRY_SLEEP
    echo "   Retry $i/$RETRY_COUNT — waiting ${RETRY_SLEEP}s..."
    sleep $RETRY_SLEEP
  done

  echo "📋 Job ID: $JOB_ID"

  if [ -z "$JOB_ID" ]; then
    echo "❌ Job ID not found, skipping..."
    echo "   Tip: To reduce skips, try increasing TX_WAIT_SLEEP or RETRY_COUNT"
    STATS_SKIPPED=$((STATS_SKIPPED + 1))
    # Refresh sequence from chain to avoid mismatch on next TX
    SEQ=$(republicd query auth account $WALLET --node $NODE -o json 2>/dev/null | jq -r '.account.value.sequence // .account.sequence // "0"')
    sleep 2
    continue
  fi

  # TX successful — increment local sequence tracker
  SEQ=$((SEQ + 1))

  # -----------------------------------------------------------------------
  # STEP 3: Run inference via local inference server
  # -----------------------------------------------------------------------
  RESULT_FILE="$JOBS_DIR/$JOB_ID/result.bin"
  mkdir -p $JOBS_DIR/$JOB_ID

  echo "⚙️  Running inference..."
  curl -s -X POST http://localhost:5555/infer \
    -H "Content-Type: application/json" \
    -d "{\"prompt\":\"What is the future of decentralized AI?\",\"output_path\":\"$RESULT_FILE\"}" > /dev/null

  if [ ! -f "$RESULT_FILE" ]; then
    echo "❌ Inference failed!"
    echo "   Is your inference server running? Check: docker ps | grep inference"
    sleep 2
    continue
  fi
  echo "✓  Inference done"

  # -----------------------------------------------------------------------
  # STEP 4: Submit job result to chain
  # Note: bech32 fix converts wallet address (rai1...) to valoper (raivaloper1...)
  # This is required due to a known chain bug in submit-job-result
  # -----------------------------------------------------------------------
  SHA256=$(sha256sum $RESULT_FILE | awk '{print $1}')

  echo "$PASSWORD" | republicd tx computevalidation submit-job-result \
    $JOB_ID \
    https://$SERVER_IP/$JOB_ID/result.bin \
    example-verification:latest \
    $SHA256 \
    --from wallet \
    --home $HOME/.republicd \
    --chain-id $CHAIN_ID \
    --gas 300000 \
    --gas-prices 2000000000arai \
    --sequence $SEQ \
    --node $NODE \
    --generate-only 2>/dev/null > /tmp/tx_unsigned2.json

  # Fix bech32 address format (wallet addr → valoper addr)
  python3 -c "
import bech32, json
tx = json.load(open('/tmp/tx_unsigned2.json'))
_, data = bech32.bech32_decode('$WALLET')
valoper = bech32.bech32_encode('raivaloper', data)
tx['body']['messages'][0]['validator'] = valoper
json.dump(tx, open('/tmp/tx_unsigned2.json', 'w'))
"

  echo "$PASSWORD" | republicd tx sign /tmp/tx_unsigned2.json \
    --from wallet \
    --home $HOME/.republicd \
    --chain-id $CHAIN_ID \
    --node $NODE \
    --output-document /tmp/tx_signed2.json 2>/dev/null

  RESULT_OUT=$(republicd tx broadcast /tmp/tx_signed2.json \
    --node $NODE \
    --chain-id $CHAIN_ID 2>&1)

  echo "$RESULT_OUT" | tee -a /root/broadcast.log | grep txhash | \
    awk '{print "🎉 Job '$JOB_ID' result submitted! TX: "$2}'

  if echo "$RESULT_OUT" | grep -q txhash; then
    STATS_COMPLETED=$((STATS_COMPLETED + 1))
  fi

  SEQ=$((SEQ + 1))
  sleep $RESULT_SLEEP
done
