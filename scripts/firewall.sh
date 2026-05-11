#!/bin/bash
# firewall.sh - apply UFW rules for a Republic validator
set -e
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 26656/tcp comment 'Tendermint p2p'
ufw allow from 127.0.0.1 to any port 26657 proto tcp comment 'RPC localhost only'
ufw allow from 127.0.0.1 to any port 1317 proto tcp comment 'REST localhost only'
ufw --force enable
ufw status verbose
