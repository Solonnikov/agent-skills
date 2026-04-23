# Networks and chain IDs

AppKit uses [CAIP-2](https://github.com/ChainAgnostic/CAIPs/blob/main/CAIPs/caip-2.md) namespaces to identify chains and [CAIP-10](https://github.com/ChainAgnostic/CAIPs/blob/main/CAIPs/caip-10.md) for addresses. Understanding this format saves a lot of confusion when parsing events.

## CAIP format

```
<namespace>:<reference>                         # chain
<namespace>:<reference>:<address>               # account
```

| Namespace | Reference meaning | Example chain | Example account |
|-----------|-------------------|---------------|-----------------|
| `eip155` | numeric EVM chain ID | `eip155:1` (Ethereum mainnet) | `eip155:1:0xAbc...` |
| `solana` | base58 cluster ID | `solana:5eykt4UsFv8P8NJdTREpY1vzqKqZKvdp` | `solana:...:<pubkey>` |
| `bip122` | genesis block hash prefix | `bip122:000000000019d6689c085ae165831e93` | `bip122:...:<p2pkh or bech32>` |

Parse every address that leaves AppKit:

```ts
function parseCaipAccount(caip: string): { type: 'evm' | 'solana' | 'bitcoin'; chainId: string; address: string } {
  const [namespace, reference, address] = caip.split(':');
  const type = namespace === 'eip155' ? 'evm' : namespace === 'solana' ? 'solana' : 'bitcoin';
  return { type, chainId: reference, address };
}
```

## Supported networks (as of this writing)

Import from `@reown/appkit/networks`:

**EVM:**
`mainnet`, `sepolia`, `arbitrum`, `arbitrumSepolia`, `optimism`, `optimismSepolia`, `polygon`, `polygonAmoy`, `base`, `baseSepolia`, `avalanche`, `bsc`, `gnosis`, `zora`, `linea`, `scroll`, `fantom`, `moonbeam`, `cronos`, `celo`, `mantle`, `blast`, `mode`, `sei`, `berachain` — plus chain IDs for testnets.

**Non-EVM:**
`solana`, `solanaDevnet`, `solanaTestnet`, `bitcoin`, `bitcoinTestnet`.

## Picking a subset

Don't paste the full list into `networks`. Pick the minimum your product supports:

- **B2C DeFi on Ethereum** — `[mainnet]` (and `sepolia` in staging).
- **Cross-L2 app** — `[mainnet, arbitrum, optimism, base, polygon]`.
- **Multichain wallet** — add `solana` and `bitcoin` as needed.

Every extra network adds to the chain-switcher UI and to your testing matrix.

## Environment-specific networks

```ts
const mainnetNetworks = [mainnet, arbitrum, base];
const stagingNetworks = [sepolia, arbitrumSepolia, baseSepolia];

const networks = import.meta.env.PROD ? mainnetNetworks : stagingNetworks;
```

Never ship a production build with testnets in the network list — users will connect to the wrong chain and lose funds.
