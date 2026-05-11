# Changelog

All notable changes to this repo are documented here.

The format loosely follows Keep a Changelog. Dates are UTC.

## [Unreleased]

### Added
- scripts/health-check.sh - quick validator status snapshot
- scripts/disk-cleanup.sh - reclaim disk space safely
- scripts/update-peers.sh - refresh persistent_peers list
- scripts/state-sync.sh - configure statesync from a trusted RPC
- scripts/unjail.sh - wrapped unjail TX with status precheck
- scripts/backup.sh - timestamped tar.gz of validator state
- scripts/monitor.sh - block height monitor with stall detection
- systemd/republicd.service - service template
- systemd/cloudflared.service - tunnel service template
- INFRASTRUCTURE.md - Vast.ai + AWS topology
- MIGRATION-VAST-AWS.md - cross-host migration runbook
- CLOUDFLARE-TUNNEL.md - dynamic IP tunnel setup
- STATE-SYNC.md - fast bootstrap procedure
- UNJAIL.md - jail recovery diagnostic + steps
- MONITORING.md - alerting strategy
- BACKUP-RECOVERY.md - disaster recovery playbook
- FAQ.md - common questions and answers
- CONTRIBUTING.md - contribution guidelines

### Removed
- empty master file at repo root (accidental artifact)

## Notes
This changelog tracks documentation and tooling in this repo.
Chain version history lives in the upstream repository.
