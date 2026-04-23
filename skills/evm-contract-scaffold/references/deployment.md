# Deployment

Two concerns: running the deploy transaction, then verifying the contract on the block explorer.

## Foundry

### Deploy script

```solidity
// script/Deploy.s.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Script, console2} from "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";

contract Deploy is Script {
    function run() external returns (MyToken token) {
        address initialOwner = vm.envAddress("OWNER");

        vm.startBroadcast();
        token = new MyToken(initialOwner);
        vm.stopBroadcast();

        console2.log("MyToken deployed at", address(token));
    }
}
```

### Run it

```bash
# Dry-run against the fork:
forge script script/Deploy.s.sol --fork-url $RPC_MAINNET

# Real deploy:
forge script script/Deploy.s.sol \
  --rpc-url mainnet \
  --broadcast \
  --verify \
  --account deployer \
  -vvvv
```

- `--account deployer` uses a keystore file you set up with `cast wallet import deployer --interactive`. Do not paste raw private keys on the command line.
- `--verify` runs `forge verify-contract` automatically after deploy.
- `-vvvv` shows reverts with stack traces.

## Hardhat

### Deploy script

```ts
// scripts/deploy.ts
import { ethers } from 'hardhat';

async function main() {
  const initialOwner = process.env.OWNER!;
  const MyToken = await ethers.getContractFactory('MyToken');
  const token = await MyToken.deploy(initialOwner);
  await token.waitForDeployment();

  console.log('MyToken deployed at', await token.getAddress());
}

main().catch(err => {
  console.error(err);
  process.exitCode = 1;
});
```

### Run it

```bash
npx hardhat run scripts/deploy.ts --network sepolia
npx hardhat verify --network sepolia <ADDRESS> "<CONSTRUCTOR_ARG_1>" "<CONSTRUCTOR_ARG_2>"
```

## Multi-network patterns

Same contract, multiple chains — keep a per-network config:

```ts
// config/networks.ts
export const NETWORKS = {
  mainnet:  { chainId: 1,     owner: '0x...' },
  sepolia:  { chainId: 11155111, owner: '0x...' },
  base:     { chainId: 8453,  owner: '0x...' },
  arbitrum: { chainId: 42161, owner: '0x...' },
};
```

Deploy script reads from this config. Record deployed addresses back to a versioned `deployments/<chain>.json`.

For Foundry, `broadcast/<script>/<chainId>/run-latest.json` records addresses automatically.

## Constructor args

If your deploy reverts at verify time with "constructor arguments do not match," you're encoding args differently than the chain recorded them. Two ways to get them right:

```bash
# Foundry: get ABI-encoded args from the broadcast log.
cast abi-encode "constructor(address,string)" 0xAbc... "MyToken"

# Hardhat verify accepts them directly:
npx hardhat verify --network mainnet <ADDRESS> "0xAbc..." "MyToken"
```

For constructor args with arrays or nested structs, pass them via a constructor args file:

```bash
forge verify-contract <ADDRESS> <CONTRACT> --constructor-args $(cast abi-encode "constructor(address[])" "[0x...,0x...]")
```

## Verification

When the built-in verifier fails — commonly on complex inheritance, custom chains, or proxy factories — see the companion skill [`hardhat-etherscan-verification`](../../hardhat-etherscan-verification/SKILL.md) for the manual Etherscan V2 API fallback.

## Deployment safety

- **Dry-run first.** Always run against a fork before broadcasting.
- **Pin the compiler version** in the deploy config. "Works on my machine" is a failure mode for verify.
- **Check contract size** before deploy. `forge build --sizes` or Hardhat's `hardhat-contract-sizer`. Mainnet limit is 24,576 bytes; going over means redeploy.
- **Pre-compute the address** if something else needs to depend on it immediately — use `CREATE2` (Foundry: `vm.computeCreate2Address`) or `CREATE3` patterns.
- **Keep a deploy log.** Every deployment, every chain, every version. Commit `deployments/<chain>.json` with addresses, block numbers, commit hashes, and compiler settings.
- **Multisig, not EOA, for production admin roles.** Transfer ownership immediately after deploy if the deployer is an EOA.
