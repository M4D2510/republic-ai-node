#!/bin/bash
# check-mempool.sh - mempool size
curl -s http://localhost:43657/num_unconfirmed_txs | jq '.result | {n_txs, total_bytes}'
