# Chain upgrades

## Pre-upgrade checklist
- Read the upgrade announcement carefully
- Confirm upgrade height and binary version
- Back up validator state (scripts/backup.sh)
- Note current peer list in case re-seeding is needed

## Manual upgrade
1. Build or download the new binary
2. Wait for the upgrade height
3. Daemon halts with UPGRADE NEEDED panic
4. Replace binary, restart daemon
5. Confirm new version with republicd version

## Cosmovisor (recommended)
Cosmovisor automates the binary swap at the upgrade height.
Pre-stage the new binary under upgrades/<plan>/bin/ and let
cosmovisor handle the switch.

## Post-upgrade
- Confirm catching_up returns to false
- Confirm signing resumes (block last_commit shows your sig)
- Watch for unexpected slashing events
