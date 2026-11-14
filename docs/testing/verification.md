# Local verification
The contract implementation reviewed is 08a3d7bdafca03c061d22160ffd0406d873101ef. The expanded test campaign was recorded at 015cade.

Run the campaign in WSL with Foundry 1.8.1 and Solidity 0.8.28.

```sh
FOUNDRY_INVARIANT_FAIL_ON_REVERT=true FOUNDRY_PROFILE=ci forge test -vv --fuzz-seed 0x1234
```

PASS: eight tests, including 10,000 fuzz cases and 512 stateful runs at depth 256, with 131,072 handler calls and zero unexpected reverts. The model checks treasury and recipient balances and pause state. Governor lifecycle coverage comes from separate integration tests.

[Raw campaign output](../../evidence/release-test.txt) · [Build sizes](../../evidence/build-sizes.txt) · [Forge lint](../../evidence/lint.txt)
