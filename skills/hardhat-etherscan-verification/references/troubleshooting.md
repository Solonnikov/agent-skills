# Troubleshooting

If verify is failing, the issue is almost always one of five things. Check in this order.

## 1. Compiler version mismatch

Symptom: "Bytecode does not match" or "Compiler version mismatch."

The deploy used one exact compiler build; verify is submitting a different one. Solidity's patch versions — `0.8.24 -> 0.8.25` — produce different bytecode even for the same source. The commit hash in the full compiler string (`v0.8.24+commit.e11b9ed9`) matters.

Fix:
- Check `hardhat.config.ts` → `solidity.version`.
- Check `artifacts/build-info/*.json` — it records the exact compiler used at deploy time.
- Use that exact version in the verify config or manual submission.

## 2. Optimizer settings

Symptom: "Bytecode does not match."

Enabled/disabled and `runs` both affect bytecode. `runs: 200` and `runs: 1000` produce different bytecode.

Fix:
- `hardhat.config.ts` → `solidity.settings.optimizer` must match deploy.
- For manual verify, pass `optimizationUsed=1/0` and `runs=N`.
- `viaIR: true` is a separate setting — if it was on at deploy, it must be on at verify.

## 3. Constructor args

Symptom: Contract verifies as "unverified" or "constructor arguments do not match."

You deployed with certain args; you're passing different args (or in a different encoding) at verify.

Fix:
- Print the exact args passed at deploy. Store them in a `deployments/<chain>.json` for every deploy.
- For complex types (arrays, structs), use `--constructor-args` pointing to a JS/TS file that exports the array — don't try to pass them as CLI strings.
- For manual V2 API, ABI-encode with the contract's constructor signature via `cast abi-encode "constructor(...)" args...`.
- Remember the `constructorArguements` typo in the V2 API.

## 4. Source doesn't match what you deployed

Symptom: "Bytecode does not match" but compiler + args are correct.

The source code in your repo is different from what was actually compiled and deployed. This happens when:

- You deployed from a flattened source but are trying to verify the original tree.
- You edited the source after deploy.
- A pre-commit hook reformatted the source after deploy.
- A different branch was checked out at deploy.

Fix:
- Use `git log` to find the commit that was deployed.
- `git checkout <commit>` and re-run verify from that state.
- Or: use the `flattened.sol` that was actually deployed, and submit it via the manual path with `codeformat=solidity-single-file`.

## 5. Library linking

Symptom: "Bytecode does not match" and your contract uses `library` imports.

External libraries get their addresses linked into the bytecode. Hardhat's plugin needs to know the library addresses to reproduce the link.

Fix:
```bash
npx hardhat verify --network mainnet <ADDRESS> \
  --libraries '{ "contracts/SafeMath.sol:SafeMath": "0xLibAddr" }' \
  "<constructor_arg>"
```

For manual V2 API, include `libraryname1`, `libraryaddress1`, up to 10 pairs in the POST body.

## Specific "this always breaks" cases

### Flattened source with duplicate licenses

`hardhat flatten` emits the SPDX header from every file. Etherscan's parser fails on multiples. Remove all but the first `// SPDX-License-Identifier: ...` line.

### Flattened source with multiple pragma lines

Same cause, same fix. Keep one `pragma solidity <ver>;` at the top.

### Proxy contracts

Verifying a proxy doesn't verify the implementation. On Etherscan, use the "Verify Proxy" UI after the implementation is verified, or hit `/api?module=contract&action=verifyproxycontract` programmatically.

### Custom chains / L2s

If `hardhat verify` says "unsupported network," add a `customChains` entry (see automated-verify.md) or skip straight to the manual V2 API with the chain's chain ID.

### "Missing dependencies" errors on the explorer

Your Solidity source imports a file that isn't in the submission. Either use standard-json format (includes every file) or make sure the flatten covered the whole tree.

### Verification "succeeded" but contract still shows as unverified

Usually a caching delay. Wait 5–10 minutes; hard-refresh the contract page. If it's still not showing, check the exact GUID status one more time — V2 sometimes returns success while the publish step is still pending.

## When to stop and ask

If you've checked all five of the above and verify still fails, the problem is usually one of:

- The chain's explorer is temporarily broken. Check their status page.
- The contract was deployed via a factory that used CREATE2 with mutated bytecode. You need to verify the factory's logic, not the "deployed contract" directly.
- The explorer doesn't support a feature you're using (custom opcodes, very new EVM features).

At that point, the fastest path is usually: contact the explorer's support with your GUID, the compiler settings, and the constructor args.
