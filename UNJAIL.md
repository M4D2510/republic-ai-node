# Unjail procedure

Validators get jailed for missing too many signing windows.
Recovery is a single TX once the node is back online and synced.

## Diagnose
1. Confirm node is synced: catching_up = false
2. Confirm signing key matches on-chain consensus pubkey
3. Check time-since-jailed exceeds slashing.downtime_jail_duration

## Unjail TX
Run republicd tx slashing unjail with:
- from: wallet
- chain-id: raitestnet_77701-1
- node: tcp://localhost:43657
- gas: 300000
- gas-prices: 2000000000arai

See scripts/unjail.sh for a wrapped version that does a status
check first and exits early if the validator is already bonded.

## Verify
Query the validator after the TX is included:
  republicd q staking validator <VALOPER> -o json | jq .jailed

Should return false within one block.

## Slashing impact
- Stake is reduced by slash_fraction_downtime (typically 0.01%)
- Delegators share the slash proportionally
- Reputation hit, especially with public dashboards watching

## Prevention beats recovery
- Run with auto-restart (systemd Restart=on-failure)
- Monitor block signing rate, not just height
- Have a documented incident response so unjail is reflex, not improvisation
