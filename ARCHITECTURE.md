# Architecture

## Components

### Validator node (Vast.ai)
Signs blocks. Single source of truth for priv_validator_state.
Reachable to the outside via Cloudflare tunnel.

### Peer set (AWS)
Four ARM hosts in us-east-1 acting as a stable seed/peer mesh.
One is configured as an archive node for historical queries.

### Indexer (yaci, Fly.io)
Reads from rpc-1-arm via gRPC, populates a PostgreSQL store
with materialized views for the explorer frontend.

### Explorer frontend
Reads from the indexer API, never directly from a chain node.

## Data flow
chain -> rpc-1-arm gRPC -> yaci indexer -> PostgreSQL ->
explorer-apis (PostgREST + custom) -> frontend

## Failure domains
- Vast.ai down: validator stops signing, peers stay up
- AWS peer down: chain unaffected, frontend stays up
- Indexer down: chain unaffected, frontend serves stale data
- DNS/Cloudflare down: external API down, validator keeps signing
