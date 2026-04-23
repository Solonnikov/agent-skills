# Setup and typed ABIs

Wagmi's correctness story depends on types. Skip typed ABIs and you lose most of the benefit.

## Install

```bash
npm install wagmi viem @tanstack/react-query
npm install -D @wagmi/cli
```

`@tanstack/react-query` is a peer dep; wagmi v2 uses it for caching and hook state.

## Wagmi config

```ts
// src/config/wagmi.ts
import { http, createConfig } from 'wagmi';
import { mainnet, arbitrum, base, polygon } from 'wagmi/chains';
import { injected, walletConnect } from 'wagmi/connectors';

export const wagmiConfig = createConfig({
  chains: [mainnet, arbitrum, base, polygon],
  transports: {
    [mainnet.id]: http(process.env.RPC_MAINNET),
    [arbitrum.id]: http(process.env.RPC_ARBITRUM),
    [base.id]: http(process.env.RPC_BASE),
    [polygon.id]: http(process.env.RPC_POLYGON),
  },
  connectors: [
    injected(),
    walletConnect({ projectId: process.env.WC_PROJECT_ID! }),
  ],
});
```

Wrap the app at the root:

```tsx
<WagmiProvider config={wagmiConfig}>
  <QueryClientProvider client={queryClient}>
    {children}
  </QueryClientProvider>
</WagmiProvider>
```

## `wagmi/cli` — generate typed bindings

```ts
// wagmi.config.ts
import { defineConfig } from '@wagmi/cli';
import { foundry, etherscan, react } from '@wagmi/cli/plugins';

export default defineConfig({
  out: 'src/generated/wagmi.ts',
  contracts: [],
  plugins: [
    foundry({ project: './contracts' }),
    etherscan({
      apiKey: process.env.ETHERSCAN_API_KEY!,
      chainId: 1,
      contracts: [
        { name: 'MyToken', address: '0x...' },
      ],
    }),
    react(),
  ],
});
```

Run `wagmi generate` to produce `src/generated/wagmi.ts`. This file:
- Exports the ABI as a `const` (satisfies viem's strict type inference).
- Exports typed hooks per contract + function: `useReadMyTokenBalanceOf`, `useWriteMyTokenTransfer`, `useSimulateMyTokenTransfer`, etc.

Commit the generated file — it's source.

## Where bindings live

```
src/
├── generated/
│   └── wagmi.ts              # auto-generated, committed
├── contracts/
│   ├── my-token/
│   │   ├── config.ts         # address per chain
│   │   ├── hooks.ts          # re-export generated hooks with defaults
│   │   └── index.ts
│   └── ...
└── config/
    └── wagmi.ts
```

## Wrapping generated hooks

Generated hooks don't know your per-chain contract addresses. Wrap them:

```ts
// src/contracts/my-token/hooks.ts
import { useReadMyTokenBalanceOf } from '@/generated/wagmi';
import { useAccount, useChainId } from 'wagmi';
import { MY_TOKEN_ADDRESS_BY_CHAIN } from './config';

export function useMyTokenBalance() {
  const { address } = useAccount();
  const chainId = useChainId();
  const contractAddress = MY_TOKEN_ADDRESS_BY_CHAIN[chainId];

  return useReadMyTokenBalanceOf({
    address: contractAddress,
    args: address ? [address] : undefined,
    query: { enabled: !!address && !!contractAddress },
  });
}
```

Consumers call `useMyTokenBalance()` — they never think about addresses or chains.
