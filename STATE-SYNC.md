# State sync

State sync gets a fresh node caught up to current height in
minutes instead of days, by downloading a snapshot from a
trusted peer rather than replaying every block.

## When to use
- New node bootstrap
- Recovering from corrupted state
- Switching hardware

## When NOT to use
- You need full history (archive node)
- You plan to query past blocks via REST/gRPC

## Steps
1. Pick 2+ trusted RPC servers with state sync enabled
2. Get latest height and a hash from N-2000 blocks back
3. Configure the statesync section in config.toml
4. Reset state but keep the address book
5. Restart and wait for snapshot apply

See scripts/state-sync.sh for an automated version that
queries the trusted RPC and writes config for you.

## Common pitfalls
- version does not exist panic: trust hash mismatch, recompute
- snapshot-only sync without WASM modules: needs archive seed
- trust period too short: bump to 168h for safety
