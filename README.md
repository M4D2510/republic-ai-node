# republic-ai-node

Operations notes, runbooks, and helper scripts for running a
Republic AI validator.

## What is here

### Runbooks
- [SETUP.md](SETUP.md) - initial validator setup
- [GETTING-STARTED.md](GETTING-STARTED.md) - quick orientation
- [LOCAL-RPC.md](LOCAL-RPC.md) - local RPC endpoint
- [MIGRATION.md](MIGRATION.md) - chain migrations
- [POINTS.md](POINTS.md) - points and rewards
- [TIPS.md](TIPS.md) - operational tips
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - common issues

### Topic deep-dives
- [INFRASTRUCTURE.md](INFRASTRUCTURE.md) - Vast.ai + AWS topology
- [MIGRATION-VAST-AWS.md](MIGRATION-VAST-AWS.md) - cross-host migration
- [CLOUDFLARE-TUNNEL.md](CLOUDFLARE-TUNNEL.md) - dynamic IP tunnel
- [STATE-SYNC.md](STATE-SYNC.md) - fast bootstrap
- [UNJAIL.md](UNJAIL.md) - jail recovery
- [MONITORING.md](MONITORING.md) - alerting strategy
- [BACKUP-RECOVERY.md](BACKUP-RECOVERY.md) - disaster recovery
- [SECURITY.md](SECURITY.md) - key and host security
- [ARCHITECTURE.md](ARCHITECTURE.md) - component layout
- [UPGRADES.md](UPGRADES.md) - chain upgrade procedure
- [FAQ.md](FAQ.md) - common questions

### Compute docs
See [compute/](compute/) for GPU compute jobs and Docker setup.

### Scripts
See [scripts/](scripts/) for health checks, disk cleanup, peer
updates, state sync, unjail, backup, monitoring, delegation,
reward withdrawal, and more.

### Templates
- [systemd/](systemd/) - service unit files
- [.github/](.github/) - issue and PR templates

## Contributing
See [CONTRIBUTING.md](CONTRIBUTING.md).

## License
[MIT](LICENSE)
