# RPC vs REST
- Tendermint RPC (26657): block, status, consensus, mempool, net_info
- Cosmos REST (1317): staking, bank, gov, distribution, slashing
Use RPC for low-level chain ops, REST for module queries.
