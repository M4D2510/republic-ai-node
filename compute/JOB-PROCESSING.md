# Republic AI - Job Processing Guide

## 1. Finding Your Jobs

### Jobs YOU submitted to yourself
```bash
republicd query txs \
  --query "message.action='/republic.computevalidation.v1.MsgSubmitJob'" \
  --node tcp://localhost:43657 -o json | \
  jq '.txs[] | select(.tx.body.messages[0].target_validator=="YOUR_VALOPER_ADDRESS") | 
  .events[] | select(.type=="job_submitted") | 
  .attributes[] | select(.key=="job_id") | .value'
```

### Jobs OTHERS submitted to you
Same command - anyone sending a job uses your valoper address as target_validator.
Replace YOUR_VALOPER_ADDRESS with your own valoper address.

### See ALL jobs on the network
```bash
republicd query txs \
  --query "message.action='/republic.computevalidation.v1.MsgSubmitJob'" \
  --node tcp://localhost:43657 -o json | \
  jq '.txs[] | .events[] | select(.type=="job_submitted") | 
  .attributes[] | select(.key=="job_id") | .value'
```

### Check if a job has been submitted already
```bash
republicd query txs \
  --query "message.action='/republic.computevalidation.v1.MsgSubmitJobResult'" \
  --node tcp://localhost:43657 -o json | \
  jq '[.txs[] | .events[] | select(.type=="job_result_submitted") | 
  .attributes[] | select(.key=="job_id") | .value]'
```

### Find unprocessed jobs (not yet submitted)
```bash
republicd query txs --query "message.action='/republic.computevalidation.v1.MsgSubmitJobResult'" \
  --node tcp://localhost:43657 -o json | \
  jq '[.txs[] | .events[] | select(.type=="job_result_submitted") | 
  .attributes[] | select(.key=="job_id") | .value] | map(tonumber)' > /tmp/submitted.json

republicd query txs --query "message.action='/republic.computevalidation.v1.MsgSubmitJob'" \
  --node tcp://localhost:43657 -o json | \
  jq '[.txs[] | .events[] | select(.type=="job_submitted") | 
  .attributes[] | select(.key=="job_id") | .value] | map(tonumber)' > /tmp/all_jobs.json

python3 -c "
import json
all_jobs = json.load(open('/tmp/all_jobs.json'))
submitted = json.load(open('/tmp/submitted.json'))
not_submitted = [j for j in all_jobs if j not in submitted]
print('Unprocessed jobs:', not_submitted)
"
```

---

## 2. Processing a Job

Once you have the Job ID, run GPU inference:
```bash
# Replace JOB_ID with the actual job number
JOB_ID=35

mkdir -p /var/lib/republic/jobs/$JOB_ID
docker run --rm --gpus all \
  -v /var/lib/republic/jobs/$JOB_ID:/output \
  republic-llm-inference:latest

echo "✅ Job $JOB_ID processed!"
ls -lh /var/lib/republic/jobs/$JOB_ID/result.bin
```

### Processing multiple jobs at once
```bash
for JOB_ID in 10 11 12 13; do
  if [ ! -f "/var/lib/republic/jobs/$JOB_ID/result.bin" ]; then
    echo "Processing Job $JOB_ID..."
    mkdir -p /var/lib/republic/jobs/$JOB_ID
    docker run --rm --gpus all \
      -v /var/lib/republic/jobs/$JOB_ID:/output \
      republic-llm-inference:latest
    echo "✅ Job $JOB_ID done!"
  else
    echo "⏭️ Job $JOB_ID already processed, skipping..."
  fi
done
```

---

## 3. Submitting Job Result

After processing, submit the result to the chain.

⚠️ **Important:** The `republicd tx computevalidation submit-job-result` command has a known bug.
Follow the workaround in [RESULT-SUBMIT-FIX.md](RESULT-SUBMIT-FIX.md)

---

## 4. Automate Everything

Instead of doing this manually, use the auto-compute script that handles everything automatically:
- Detects new jobs
- Runs GPU inference
- Submits results

See [AUTO-COMPUTE.md](AUTO-COMPUTE.md) for setup instructions.

---

## Notes
- Only the target validator can submit the result for a job
- You cannot process or submit results for jobs sent to other validators
- Make sure HTTP server is running: `cd /var/lib/republic/jobs && python3 -m http.server 8080 &`
- Validator must be BONDED to submit results
