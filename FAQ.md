# FAQ

Common questions when running or onboarding a Republic AI validator.

## Setup

### Q: Which hardware do I need?
For testnet: 4 vCPU, 8GB RAM, 200GB SSD is comfortable.
For mainnet workloads: bump to 8 vCPU, 16GB RAM, 500GB NVMe.

### Q: Can I run on a Vast.ai container?
Yes. The dynamic IP is the only friction, and Cloudflare tunnel
solves it. See CLOUDFLARE-TUNNEL.md.

### Q: Do I need to compile from source?
No. Prebuilt binaries cover the common platforms. Compile only
if you need a custom build or are on an unusual architecture.

## Operations

### Q: How do I know if I am signing blocks?
Watch precommits in the most recent N blocks via REST:
  curl -s $REST/blocks/latest | jq .block.last_commit.signatures
Your consensus address should appear, not be a zeroed entry.

### Q: My node got jailed. Now what?
See UNJAIL.md. TL;DR: confirm synced, then run scripts/unjail.sh.

### Q: How often should I rotate keys?
Validator signing keys are not rotated in Cosmos SDK. Operator
wallet keys can and should be rotated if exposed.

## Troubleshooting

### Q: catching_up stays true forever
Check peers. If persistent_peers is empty or stale, run
scripts/update-peers.sh and restart.

### Q: Disk full on chain home partition
Run scripts/disk-cleanup.sh first. If still tight, consider
disabling tx_index in config.toml (saves significant space).

### Q: Block height stops advancing
Usually a network partition. Check peers, RPC reachability,
and that systemd has not stopped republicd.

## Economics

### Q: How are rewards distributed?
See POINTS.md for the points and reward breakdown.

### Q: Can I slash myself accidentally?
Yes - by running two nodes with the same priv_validator_key.
Never do this. See BACKUP-RECOVERY.md double-sign section.
