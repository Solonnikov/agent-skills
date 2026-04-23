# Manual V2 API fallback

When `hardhat verify` fails with a bytecode-mismatch and you've ruled out compiler settings, submit directly to the Etherscan V2 API. This works for contracts deployed from flattened source, contracts on newer chains the plugin doesn't know yet, and any case where the plugin's opinionated bytecode matching is getting in your way.

## Flatten the source

```bash
npx hardhat flatten contracts/MyContract.sol > flattened.sol
```

The output contains every imported file concatenated. It usually has:
- Multiple `// SPDX-License-Identifier: MIT` lines — Etherscan V2 only wants one. Remove duplicates.
- Multiple `pragma solidity` lines — keep one, matching the version.
- Duplicate type definitions — rare, but possible with diamond inheritance. Deduplicate.

After cleanup, `flattened.sol` is a single-file Solidity source that compiles on its own.

## ABI-encode constructor args

```bash
# Using Foundry's `cast`:
cast abi-encode "constructor(address,string)" 0xAbc... "MyToken"
# → 0x000...Abc...MyTokenPadded
```

Strip the `0x` prefix — the API wants raw hex.

With ethers v6:

```ts
import { AbiCoder } from 'ethers';
const encoded = AbiCoder.defaultAbiCoder().encode(
  ['address', 'string'],
  ['0xAbc...', 'MyToken'],
).slice(2);  // strip 0x
```

## POST to V2 API

Endpoint: `https://api.etherscan.io/v2/api?chainid=<CHAIN_ID>`

V2 uses a single unified host for every supported chain — you pass the `chainid` as a query param instead of hitting a per-chain subdomain.

Request body (`application/x-www-form-urlencoded`):

| Field | Value |
|-------|-------|
| `apikey` | Your Etherscan API key |
| `module` | `contract` |
| `action` | `verifysourcecode` |
| `contractaddress` | `0x...` deployed address |
| `sourceCode` | Full flattened source (as a string) |
| `codeformat` | `solidity-single-file` |
| `contractname` | Name of the contract to verify (matches the `contract Foo {}` name) |
| `compilerversion` | Full compiler string, e.g. `v0.8.24+commit.e11b9ed9` — must match exactly |
| `optimizationUsed` | `1` or `0` |
| `runs` | Optimizer runs (only meaningful if `optimizationUsed=1`) |
| `constructorArguements` | ABI-encoded constructor args hex (no `0x`). Note the typo — Etherscan spells it "Arguements". |
| `evmversion` | Optional — leave blank for default, or match your `hardhat.config.ts` setting |
| `licenseType` | `3` for MIT, `1` for unlicensed. Full list in Etherscan docs |
| `viaIR` | `1` if deployed with `viaIR: true`, else omit |

Full submission script:

```ts
// scripts/verify-v2.ts
import fs from 'node:fs';
import { setTimeout } from 'node:timers/promises';

const CHAIN_ID = 1;  // 1=mainnet, 11155111=sepolia, 8453=base, 42161=arbitrum, 137=polygon
const ADDRESS = '0xDeployedAddress';
const CONTRACT_NAME = 'MyContract';
const COMPILER = 'v0.8.24+commit.e11b9ed9';
const OPTIMIZER_RUNS = 200;
const CONSTRUCTOR_ARGS_HEX = '000...';  // from cast abi-encode, no 0x

async function submit() {
  const source = fs.readFileSync('flattened.sol', 'utf-8');

  const body = new URLSearchParams({
    apikey: process.env.ETHERSCAN_API_KEY!,
    module: 'contract',
    action: 'verifysourcecode',
    contractaddress: ADDRESS,
    sourceCode: source,
    codeformat: 'solidity-single-file',
    contractname: CONTRACT_NAME,
    compilerversion: COMPILER,
    optimizationUsed: '1',
    runs: String(OPTIMIZER_RUNS),
    constructorArguements: CONSTRUCTOR_ARGS_HEX,
    licenseType: '3',
  });

  const res = await fetch(`https://api.etherscan.io/v2/api?chainid=${CHAIN_ID}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body,
  });
  const data = await res.json();

  if (data.status !== '1') {
    throw new Error(`Submission failed: ${data.result}`);
  }

  const guid = data.result as string;
  console.log('Submitted. GUID:', guid);
  return guid;
}

async function pollStatus(guid: string) {
  for (let i = 0; i < 20; i++) {
    await setTimeout(15_000);

    const params = new URLSearchParams({
      apikey: process.env.ETHERSCAN_API_KEY!,
      module: 'contract',
      action: 'checkverifystatus',
      guid,
    });
    const res = await fetch(`https://api.etherscan.io/v2/api?chainid=${CHAIN_ID}&${params}`);
    const data = await res.json();

    if (data.status === '1') {
      console.log('Verified.');
      return;
    }
    if (data.result === 'Pending in queue') {
      console.log(`[${i + 1}/20] ${data.result}`);
      continue;
    }
    throw new Error(`Verify failed: ${data.result}`);
  }
  throw new Error('Timed out waiting for verification');
}

(async () => {
  const guid = await submit();
  await pollStatus(guid);
})();
```

## Multi-file submission (if you don't want to flatten)

Use `codeformat: 'solidity-standard-json-input'` and submit the entire compiler input JSON:

```ts
const standardJson = {
  language: 'Solidity',
  sources: {
    'contracts/MyContract.sol': { content: fs.readFileSync('contracts/MyContract.sol', 'utf-8') },
    'contracts/Dep.sol':        { content: fs.readFileSync('contracts/Dep.sol', 'utf-8') },
    // every file in the tree that was compiled
  },
  settings: {
    optimizer: { enabled: true, runs: 200 },
    outputSelection: { '*': { '*': ['*'] } },
  },
};

body.append('codeformat', 'solidity-standard-json-input');
body.append('sourceCode', JSON.stringify(standardJson));
```

Standard JSON is fussier but preserves the original file layout — no flatten dedup headaches.

## Chain IDs and hostnames

The V2 API is unified under `api.etherscan.io/v2/api`. The V1 API still works and uses per-chain hosts:

| Chain | V1 host | V2 chain ID |
|-------|---------|-------------|
| Ethereum mainnet | `api.etherscan.io` | 1 |
| Sepolia | `api-sepolia.etherscan.io` | 11155111 |
| Base | `api.basescan.org` | 8453 |
| Arbitrum One | `api.arbiscan.io` | 42161 |
| Polygon | `api.polygonscan.com` | 137 |
| Optimism | `api-optimistic.etherscan.io` | 10 |
| BNB Chain | `api.bscscan.com` | 56 |

V2 is simpler and consistent. Use it unless the chain you care about hasn't migrated yet.
