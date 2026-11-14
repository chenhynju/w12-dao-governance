# Base Sepolia deployment record

| Gate | Recorded result |
| --- | --- |
| Target | Base Sepolia, chain ID 84532 |
| Local deployment script | PASS with synthetic role addresses |
| RPC preflight | Windows read-only chain ID check PASS. Three WSL RPC probes timed out |
| Faucet and funding | BLOCKED. Faucet page timed out and candidate address 0x568Fa7993b0C425B34e39078d46b7e32891b99C2 returned 0 ETH at the recorded check |
| Public deployment | BLOCKED. No broadcast or receipt in project evidence |
| Source verification and public smoke tests | NOT RUN |

[Local deployment simulation](../../evidence/deploy-simulation.txt) contains simulator addresses. To resume, confirm WSL chain ID and signer balance, review the distributor and guardian configuration, simulate the deployment against the target RPC, then capture broadcast receipts, verify source, and check Timelock roles and proxy configuration on-chain.
