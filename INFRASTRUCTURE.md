# Infrastructure overview

Topology of a Republic AI validator deployment spanning Vast.ai
(primary) and AWS (peers + RPC fallback).

## Vast.ai node
- Role: validator (signing keys)
- Network: dynamic IP exposed via Cloudflare tunnel
- Chain home: /root/.republicd
- RPC: tcp://localhost:43657
- REST: http://localhost:43317

## AWS peers (us-east-1, ARM)
| Role        | Public IP        |
|-------------|------------------|
| val0-arm    | 32.195.95.92     |
| val2-arm    | 54.163.45.48     |
| rpc-1-arm   | 54.243.22.128    |
| state-sync  | 54.204.89.111    |

## Public endpoints
- explorer.republicai.io
- rest.republicai.io
- rpc.republicai.io
- grpc.republicai.io:443

## Resilience
- Cloudflare tunnel ID is IP-immune
- AWS peers serve as stable seed list
- rpc-1-arm is an archive node (historical queries via x-cosmos-block-height)
