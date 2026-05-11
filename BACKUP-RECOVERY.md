# Backup and disaster recovery

What to back up, how often, and how to restore.

## What to back up
1. priv_validator_key.json   - signing key (CRITICAL)
2. node_key.json             - p2p identity
3. priv_validator_state.json - last-signed state (prevents double-sign)
4. genesis.json              - chain genesis
5. config/                   - your customizations

## What NOT to back up
- data/ directory (multi-GB, restorable via state sync)
- tx_index.db (rebuildable from blocks)
- snapshots/ (regeneratable on demand)

## Frequency
- After any config change: take a backup
- Daily cron: scripts/backup.sh

## Off-site storage
- Encrypted upload to S3, B2, or similar nightly
- Never store the validator key as plain text anywhere
- Consider Shamir-splitting the key for high-stakes setups

## Recovery scenarios

### Lost host, key in hand
1. Provision new host
2. Restore tar.gz from backup
3. Start node with state sync to catch up
4. Confirm signing resumes within one block window

### Lost both host and key
- The validator is permanently lost
- Wait for unbonding period, withdraw delegations
- Create a new validator under a fresh moniker

### Suspected double-sign
- Stop the node immediately
- Compare priv_validator_state.json against on-chain last signed height
- Do not restart until certain only one instance is running

## Test your backups
A backup you never restored is not a backup. Run a dry-run
restore on a throwaway host every quarter.
