#!/bin/bash
# vote.sh - vote on a governance proposal
PROP="${1:?Usage: vote.sh <proposal_id> <yes|no|abstain|no_with_veto>}"
OPT="${2:?Usage: vote.sh <proposal_id> <yes|no|abstain|no_with_veto>}"
republicd tx gov vote "$PROP" "$OPT" --from wallet --chain-id raitestnet_77701-1 --gas 200000 --gas-prices 2000000000arai --yes
