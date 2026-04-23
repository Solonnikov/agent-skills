# Automated verify (plugin path)

For most contracts, `@nomicfoundation/hardhat-verify` handles the whole flow. This is the happy path.

## Install

```bash
npm install --save-dev @nomicfoundation/hardhat-verify
```

## Configure

```ts
// hardhat.config.ts
import '@nomicfoundation/hardhat-verify';

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.24',
    settings: { optimizer: { enabled: true, runs: 200 } },
  },
  networks: {
    mainnet:  { url: process.env.RPC_MAINNET!,  accounts: [process.env.PRIVATE_KEY!] },
    sepolia:  { url: process.env.RPC_SEPOLIA!,  accounts: [process.env.PRIVATE_KEY!] },
    base:     { url: process.env.RPC_BASE!,     accounts: [process.env.PRIVATE_KEY!] },
    arbitrum: { url: process.env.RPC_ARBITRUM!, accounts: [process.env.PRIVATE_KEY!] },
    polygon:  { url: process.env.RPC_POLYGON!,  accounts: [process.env.PRIVATE_KEY!] },
  },
  etherscan: {
    // One key per chain. Each chain has its own explorer API key.
    apiKey: {
      mainnet:  process.env.ETHERSCAN_API_KEY!,
      sepolia:  process.env.ETHERSCAN_API_KEY!,
      base:     process.env.BASESCAN_API_KEY!,
      arbitrumOne: process.env.ARBISCAN_API_KEY!,
      polygon:  process.env.POLYGONSCAN_API_KEY!,
    },
  },
  sourcify: {
    enabled: true,  // also publish to Sourcify as a secondary verification
  },
};
```

## Run

```bash
# Basic: constructor args as separate positional strings.
npx hardhat verify --network base <ADDRESS> "<arg1>" "<arg2>"

# Constructor that takes a complex arg (tuple, array): pass via a JS module.
npx hardhat verify --network base --constructor-args ./verify-args.ts <ADDRESS>
```

`verify-args.ts`:

```ts
module.exports = [
  '0xAbc...',           // address
  'MyToken',            // string
  ['0x1...', '0x2...'], // address[]
  { field: 42n },       // tuple-ish
];
```

The plugin compiles locally, retrieves the deployed bytecode, compares, then POSTs to the explorer API.

## Useful flags

| Flag | Effect |
|------|--------|
| `--network <name>` | Required. Must match an entry in `networks`. |
| `--contract contracts/Foo.sol:Foo` | Specify which contract if multiple with the same name exist. |
| `--constructor-args <path>` | Load args from a JS/TS module — needed for complex types. |
| `--libraries '{ "LibA": "0x..." }'` | If your contract links external libraries. |

## Common failure modes

### "Unable to verify the contract"

Usually means the bytecode doesn't match. Before jumping to the V2 API fallback, check:

- Exact compiler version (`solc-js` metadata includes the minor version).
- Optimizer runs.
- Whether you deployed with `viaIR: true` — if so, add it to verify config.
- Whether you deployed from a flattened source — the standard plugin will fail on the original tree.

### "Missing or invalid API Key"

The `etherscan.apiKey` entry doesn't match the chain name the plugin expects. For custom chains, add a manual entry:

```ts
etherscan: {
  apiKey: { myCustomChain: process.env.MY_KEY! },
  customChains: [
    {
      network: 'myCustomChain',
      chainId: 12345,
      urls: {
        apiURL: 'https://api.mychain.com/api',
        browserURL: 'https://mychain.com',
      },
    },
  ],
},
```

### "Already verified"

Not a failure — the contract's already good. You're done.

### "Bytecode does not match"

This is where the manual V2 API fallback earns its keep. See `manual-v2-api.md`.

## Scripting verify into deploy

```ts
// scripts/deploy-and-verify.ts
import { ethers, run } from 'hardhat';

async function main() {
  const Token = await ethers.getContractFactory('MyToken');
  const token = await Token.deploy(initialOwner);
  await token.waitForDeployment();
  const address = await token.getAddress();
  console.log('Deployed at', address);

  // Wait a few blocks — explorer indexers need a moment.
  await new Promise(r => setTimeout(r, 30_000));

  try {
    await run('verify:verify', {
      address,
      constructorArguments: [initialOwner],
    });
  } catch (err: any) {
    if (err.message.includes('Already Verified')) return;
    console.warn('Verify failed; fall back to manual:', err);
  }
}
```

One command, one outcome. Fall back to the manual path only when this one returns a bytecode-mismatch kind of failure.
