# Project setup — Foundry and Hardhat side by side

Foundry is the default recommendation. Hardhat is fine if the team is TypeScript-native or you need specific plugins (upgrades proxy admin, a particular verify plugin, deployment orchestration).

## Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
forge init my-contracts
cd my-contracts
forge install OpenZeppelin/openzeppelin-contracts
```

### File tree

```
my-contracts/
├── foundry.toml
├── remappings.txt
├── src/
│   └── MyContract.sol
├── test/
│   └── MyContract.t.sol
├── script/
│   └── Deploy.s.sol
└── lib/                    # forge-managed dependencies (not committed)
```

### `foundry.toml`

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc_version = "0.8.24"
optimizer = true
optimizer_runs = 200

[rpc_endpoints]
mainnet = "${RPC_MAINNET}"
sepolia = "${RPC_SEPOLIA}"
base = "${RPC_BASE}"

[etherscan]
mainnet = { key = "${ETHERSCAN_API_KEY}" }
sepolia = { key = "${ETHERSCAN_API_KEY}" }
base    = { key = "${BASESCAN_API_KEY}", url = "https://api.basescan.org/api" }
```

### `remappings.txt`

```
@openzeppelin/=lib/openzeppelin-contracts/
forge-std/=lib/forge-std/src/
```

Keep remappings small and readable. Git-managed dependencies go here.

## Hardhat

```bash
npm init -y
npm install --save-dev hardhat
npx hardhat init    # pick "TypeScript project"
npm install --save-dev @nomicfoundation/hardhat-toolbox @nomicfoundation/hardhat-verify
npm install @openzeppelin/contracts
```

### File tree

```
my-contracts/
├── hardhat.config.ts
├── package.json
├── tsconfig.json
├── contracts/
│   └── MyContract.sol
├── test/
│   └── MyContract.ts
└── scripts/
    └── deploy.ts
```

### `hardhat.config.ts`

```ts
import { HardhatUserConfig } from 'hardhat/config';
import '@nomicfoundation/hardhat-toolbox';
import '@nomicfoundation/hardhat-verify';
import 'dotenv/config';

const config: HardhatUserConfig = {
  solidity: {
    version: '0.8.24',
    settings: { optimizer: { enabled: true, runs: 200 } },
  },
  networks: {
    mainnet: { url: process.env.RPC_MAINNET ?? '', accounts: [process.env.PRIVATE_KEY!] },
    sepolia: { url: process.env.RPC_SEPOLIA ?? '', accounts: [process.env.PRIVATE_KEY!] },
    base:    { url: process.env.RPC_BASE    ?? '', accounts: [process.env.PRIVATE_KEY!] },
  },
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_API_KEY!,
      sepolia: process.env.ETHERSCAN_API_KEY!,
      base:    process.env.BASESCAN_API_KEY!,
    },
  },
};

export default config;
```

## Choosing between them

| Concern | Foundry | Hardhat |
|---------|---------|---------|
| Test speed | Much faster (Rust runner) | Slower (Node.js) |
| Test language | Solidity (same as code) | TypeScript |
| Fuzzing | First-class, free | Via plugins |
| Invariant testing | Built-in | Via plugins |
| Forking | Built-in, fast | Built-in, slower |
| Deployment orchestration | Scripts (less ergonomic for chains of deploys) | Better for complex multi-step deploys |
| Plugin ecosystem | Smaller but growing | Large, mature |
| Upgradeability tooling | Community libraries | `@openzeppelin/hardhat-upgrades` is excellent |
| Typescript client types | Via `forge bind` or `wagmi/cli` | TypeChain built-in |

**Default to Foundry** unless one of these applies:
- You need `@openzeppelin/hardhat-upgrades` for proxy management.
- Your deployment is a multi-contract orchestration and you want TypeScript's power.
- Your team is strongly TypeScript-native and doesn't want to read Solidity tests.

You can also use both — write contracts with Foundry tests, deploy with Hardhat. It's extra config to maintain but legitimate.

## `.gitignore` essentials

```
# Foundry
out/
cache/
broadcast/
lib/

# Hardhat
node_modules/
artifacts/
cache/
typechain-types/

# Env
.env
.env.*.local

# Editor
.vscode/
.idea/
```
