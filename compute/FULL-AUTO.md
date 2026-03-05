# Republic AI - Full Auto Compute Script

This script fully automates the entire compute workflow in a single loop:
1. Submits a new job to the chain
2. Retrieves the Job ID from the transaction
3. Runs GPU inference using Docker
4. Submits the result back to the chain
5. Repeats every ~60 seconds

## How It Works

Each cycle the script performs the following steps:

Step 1 - Job Submission: Submits a new compute job to your validator address on-chain. The job fee is configurable (we use 0.005 RAI).

Step 2 - Job ID Retrieval: Waits 15 seconds for the TX to be included in a block, then queries the TX hash to extract the Job ID.

Step 3 - GPU Inference: Runs the republic-llm-inference:latest Docker container with GPU acceleration. A 60-second timeout is enforced to prevent the container from hanging indefinitely.

Step 4 - Result Submission: Computes the SHA256 hash of the result file, applies the bech32 address fix, signs the TX manually, and broadcasts it to the chain.

Step 5 - Watchdog: A separate watchdog script monitors the main script and automatically restarts it if it crashes or stops.

## Prerequisites

- Node fully synced (catching_up: false)
- TX indexer enabled (indexer = "kv" in config.toml)
- REST API enabled (enable = true in app.toml)
- Docker with GPU support installed
- republic-llm-inference:latest Docker image built locally
- HTTP server running on port 8080
- Validator must be BONDED

## Setup

### 1. Create the script

Save the script to /root/full-auto.sh and configure the variables below.

### 2. Configure variables

| Variable | Description | Example |
|----------|-------------|---------|
| VALOPER | Your validator operator address | raivaloper1xxx... |
| WALLET | Your wallet address | rai1xxx... |
| SERVER_IP | Your server public IP | 142.170.89.112 |
| PASSWORD | Your keyring password | your_password |
| JOB_FEE | Fee per job in arai | 5000000000000000arai (0.005 RAI) |

### 3. Create the watchdog script

Save the watchdog script to /root/watchdog.sh

### 4. Start both scripts
nohup /root/full-auto.sh > /root/full-auto.log 2>&1 &
nohup /root/watchdog.sh > /root/watchdog.log 2>&1 &
echo "Full Auto + Watchdog started!"


### 5. Monitor
tail -f /root/full-auto.log


### 6. Stop
pkill -f full-auto.sh
pkill -f watchdog.sh


## Performance

| Metric | Value |
|--------|-------|
| GPU | NVIDIA RTX 3090 |
| Inference time | ~7-8 seconds |
| Cycle time | ~60 seconds |
| Jobs per hour | ~40-50 |
| Job fee | 0.005 RAI |

## Known Issues and Solutions

### 1. Docker Container Stuck
Problem: Docker inference container hangs indefinitely.
Solution: Added timeout 60 before docker run. If inference takes more than 60 seconds, the container is force-killed.

### 2. Account Sequence Mismatch
Problem: Submitting transactions too quickly causes sequence mismatch errors.
Solution: Added sleep 15 after job submission and sleep 15 after result submission.

### 3. Script Crashes
Problem: Main script may stop due to unexpected errors.
Solution: Watchdog script checks every 30 seconds and automatically restarts the main script if stopped.

### 4. Job ID Not Found
Problem: TX broadcast but Job ID cannot be retrieved yet.
Solution: Added sleep 15 after job submission. If Job ID still not found, script skips and continues.

### 5. Bech32 Address Bug
Problem: submit-job-result sends rai prefix instead of raivaloper, TX rejected.
Solution: Generate unsigned TX with --generate-only, fix validator address with Python, sign and broadcast manually.
Full details: RESULT-SUBMIT-FIX.md

### 6. HTTP Server Not Running
Problem: Result fetch endpoint returns 404.
Solution: Start HTTP server before running the script:
cd /var/lib/republic/jobs && python3 -m http.server 8080 &


## Notes

- Script submits one job per cycle to avoid sequence mismatch errors
- Watchdog ensures 24/7 operation without manual intervention
- All results show PendingValidation status on testnet - this is expected
- For monitoring-only script see AUTO-COMPUTE.md
