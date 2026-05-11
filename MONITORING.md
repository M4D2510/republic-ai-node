# Monitoring and alerting

Minimum viable monitoring for a single-node validator. Start
here, add complexity only when paged.

## What to watch
1. Block height (advancing)
2. catching_up flag
3. Validator jailed state
4. Disk usage on chain home partition
5. CPU load (sustained 100% = problem)
6. Network reachability of public RPC

## Lightweight setup
- scripts/monitor.sh in a tmux pane for block height + stall detection
- A daily cron running scripts/health-check.sh and emailing the output
- Discord webhook on jail or stall events

## When ready for more
- Prometheus + Grafana dashboards
- Tendermint exporter for block metrics
- Node exporter for host metrics
- Alertmanager routing to PagerDuty or Discord

## Alerting golden rules
- Page only on actionable events
- Tune thresholds after one week of observation
- Always include the recovery runbook in alert text
- Test the page path quarterly

## What to log forever
- Every jail event with timestamp and root cause
- Every config change with diff and reason
- Every fork or chain halt and how you handled it

Future-you will thank present-you for the paper trail.
