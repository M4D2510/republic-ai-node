# Migrating between Vast.ai and AWS

Notes for moving a Republic validator between Vast.ai and AWS,
or running a hybrid setup with one acting as hot spare.

## Prep
1. Backup priv_validator_key.json and node_key.json
2. Note current block height on the active node
3. Verify firewall rules on destination (26656, 26657, 1317)

## Cold migration steps
1. Stop republicd on source: systemctl stop republicd
2. Copy entire ~/.republicd via rsync over SSH
3. Update config.toml external_address if needed
4. Start republicd on destination
5. Confirm signing resumes within one block window

## Hot spare strategy
- Never run two nodes with the same priv_validator_key simultaneously
- Double-signing causes slashing - use priv_validator_state.json
  as a single source of truth
- Promote spare only after confirming source is down

## Reverse migration
The same playbook works in either direction. Vast.ai is cheaper
per hour but has dynamic IP; AWS has stable IP but costs more.
Pick based on workload, not religion.
