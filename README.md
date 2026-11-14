# Portfolio DAO

An EVM governance prototype that uses delegated voting to authorize delayed treasury payments and UUPS upgrades.

## Quick start

Use Foundry 1.8.1 and run `forge build` followed by `FOUNDRY_PROFILE=ci forge test -vv --fuzz-seed 0x1234`. Dependencies are vendored from the local D01 source snapshot (OpenZeppelin 5.0.2 and forge-std 1.14.0).

## Governance

1. Distribute the fixed 1,000,000 DAOG supply and delegate voting power.
2. A proposer with at least 10,000 DAOG in historical voting power submits a batch.
3. Voting opens after 7,200 blocks. Voters use historical delegated balances. The voting period is 36,000 blocks and quorum is 4% of historical supply.
4. Queue a successful proposal through the Governor. After the two-day timelock, anyone can trigger Governor execution.
5. The treasury accepts instructions from the timelock. A guardian can pause payments. Governance can replace the guardian and resume payments.

Parameters expressed in blocks depend on the chain's block cadence. Initial token distribution determines effective governance control.

## Source and evidence

- [Governor and voting token](src/Dao.sol) and [Treasury](src/Treasury.sol)
- [Deployment script](script/Deploy.s.sol) and [role inputs](.env.example)
- [Governance tests](test/Dao.t.sol) and [CI-profile test output](evidence/ci-test.txt)
- [AI-assisted security self-assessment](docs/audit/self-assessment.md)

The contract prototype accepts a guardian address, including a multisig. The test fixture uses an EOA. A wallet dashboard, deployed multisig integration and public deployment remain pending.
