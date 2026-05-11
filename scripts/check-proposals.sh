#!/bin/bash
# check-proposals.sh - active governance proposals
curl -s "http://localhost:43317/cosmos/gov/v1/proposals?proposal_status=PROPOSAL_STATUS_VOTING_PERIOD" | jq
