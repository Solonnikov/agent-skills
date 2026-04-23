# Initialization and adapter configuration

One init function per app. Call it once, on-demand (e.g. when the user first clicks "Connect"), not at module load — AppKit pulls in a lot of code you don't want in your critical path.

## Minimal init

```ts
import { createAppKit } from '@reown/appkit';
import { WagmiAdapter } from '@reown/appkit-adapter-wagmi';
import { SolanaAdapter } from '@reown/appkit-adapter-solana';
import { BitcoinAdapter } from '@reown/appkit-adapter-bitcoin';
import { mainnet, arbitrum, polygon, base } from '@reown/appkit/networks';
import { solana, bitcoin } from '@reown/appkit/networks';

const projectId = process.env.REOWN_PROJECT_ID!;

const wagmiAdapter = new WagmiAdapter({
  projectId,
  networks: [mainnet, arbitrum, polygon, base],
});

const solanaAdapter = new SolanaAdapter({
  registerWalletStandard: true,
});

const bitcoinAdapter = new BitcoinAdapter();

const modal = createAppKit({
  adapters: [wagmiAdapter, solanaAdapter, bitcoinAdapter],
  networks: [mainnet, arbitrum, polygon, base, solana, bitcoin],
  metadata: {
    name: 'Your App Name',
    description: 'One-line description shown in the wallet prompt',
    url: window.location.origin,
    icons: [`${window.location.origin}/icon-512.png`],
  },
  projectId,
  features: {
    analytics: true,
    email: false,
    socials: false,
  },
  enableReconnect: false,
  allowUnsupportedChain: true,
});
```

## Options worth knowing

| Option | What it does | When to change |
|--------|--------------|----------------|
| `adapters` | Which chain families are supported. | Drop unused ones to cut bundle size. |
| `networks` | Which specific networks appear in the selector. | Subset for your product (e.g. mainnet + one testnet in staging). |
| `metadata` | Shown in the wallet confirmation UI. | Match your brand; wrong metadata here is a phishing vector for users. |
| `features.email` | Enables email login via social auth. | Default off unless you've reviewed the UX and privacy tradeoffs. |
| `enableReconnect` | Auto-reconnect on page load. | Turn on once you've reconciled state on mount (see state.md). |
| `allowUnsupportedChain` | Lets users stay connected on chains not in your `networks` list. | `false` in strict mode; `true` if you want to show a "switch network" prompt yourself. |
| `featuredWalletIds` | Curated wallet list shown first. | Surface the wallets your users actually have. |
| `excludeWalletIds` | Wallets hidden entirely. | Regulatory or quality reasons. |

## Tearing down

AppKit does not expose a public `destroy()`. To cleanly disconnect and rebuild:

1. Call `modal.disconnect()`.
2. Unsubscribe from every `modal.subscribe*()` callback you stored.
3. Remove any native wallet listeners (see state.md).
4. Null out your state: `modal`, `wagmiConfig`, connection fields.

Then you can call `createAppKit` again safely.

## Bundle size

AppKit + three adapters adds ~300–400 KB gzipped. Common mitigations:

- Lazy-load the wallet module (dynamic `import()`) on first interaction.
- Code-split the connect button into its own chunk.
- Drop adapters you don't need — `bitcoinAdapter` alone is ~40 KB.
