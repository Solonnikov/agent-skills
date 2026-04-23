# Client layer

The frontend is where users experience the trust boundaries you designed. Bad client architecture can make a sound dApp feel broken; good architecture can make a minimalist one feel magical.

For wallet integration mechanics, see the `reown-appkit-web3` and `wagmi-contract-interaction` skills. This reference is about how the client as a system fits together.

## Rendering model

Pick one:

### Client-side SPA (React / Angular / Svelte default)

- User loads the app; everything after is JS.
- Wallet integration is straightforward.
- State can be local, no server round-trip.
- **SEO/shareability weak** — server sees empty HTML.
- **Cold-start slow** — bundle + chain reads happen on first render.

Use for: tools, dashboards, power-user apps where users return and shareability doesn't matter.

### SSR / partial-SSR (Next.js, Nuxt, SvelteKit, Angular Universal)

- Server renders initial HTML with data.
- Fast first paint; good SEO.
- Wallet state initializes post-hydration (wallet is a browser API).
- **More infrastructure** — server must run, caches must be warm.

Use for: public-facing apps where search/shareability matters, content-heavy dApps (NFT marketplaces, profile pages).

### SSG (Astro, Next static export)

- HTML prebuilt at build time.
- Fast, cheap.
- **Dynamic chain data needs client-side fetching.** Hybrid pattern: SSG the shell; hydrate the live parts.

Use for: marketing pages, documentation, content that updates on deploy cadence.

**Honest read:** most dApp teams over-engineer this. If you're not sure, ship an SPA. Moving to SSR later is not catastrophic.

## State shape

Client state has four common shapes. Don't mix them.

### 1. Wallet / connection state

- Is there a wallet connected?
- Which chain?
- Which address?
- Wallet capabilities (signs, sends transactions, supports EIP-1271).

Usually lives in the wallet SDK (wagmi, Reown, etc.) and you mirror what you need into your state library.

### 2. On-chain state (reads)

- Balances, allowances, NFT holdings.
- Protocol state (current auction, pool state, etc.).
- User-specific state (their position, their rewards, their delegation).

Always fetched from chain or indexer. Caching strategy is critical:
- **Fresh**: re-fetch on every relevant action. Expensive.
- **Cached with invalidation**: React Query / SWR / TanStack Query. Invalidate on transaction success.
- **Watch-mode**: subscribe to new blocks, re-fetch on change. Costly — one subscription per watched value.
- **Event-driven**: listen to contract events, update local state on match.

Pattern:
```
Initial load: fetch from indexer (fast, historical).
During session: listen to events for the specific entities user cares about.
After user's own transactions: optimistic update → confirm → reconcile on receipt.
```

### 3. Transaction state

- Simulating
- Pending signature
- Broadcast (have hash)
- Confirming
- Successful / failed

Keep this per-transaction, locally. Users expect to see every step. See `wagmi-contract-interaction` for the simulate → write → wait flow.

### 4. UI state

- Modals open, forms in progress, current tab.
- Lives in component state or a lightweight store (Zustand, Jotai, signals).
- Usually doesn't touch on-chain state.

## Caching strategy

React Query (or equivalent) is the default for dApp frontends.

Key per-query:
```ts
['contract', contractAddress, 'function', fnName, ...args, { chainId }]
```

Invalidate after:
- A user's own transaction succeeds.
- An event you care about fires.
- A `stale-while-revalidate` timer expires (e.g. 60s for price data).

Avoid:
- Caching across chains with the same key.
- Caching transaction-status queries at all (they change fast).
- Not invalidating after user actions (makes the UI feel frozen).

## Error UX — the single biggest differentiator

Most dApps handle errors poorly. Getting this right is cheap and massive UX.

### Error categories users face

| Category | User meaning | UI |
|----------|--------------|-----|
| Wallet not connected | "Connect first" | Show connect button, not error. |
| Wrong chain | "Switch network" | Explicit button + current vs required chain. |
| Insufficient gas / ETH | "Top up wallet" | Explain, maybe bridge link. |
| Insufficient token balance | "Get more token" | Explain; if a swap exists, link to it. |
| User rejected signature | (user action) | Silent. No toast, no error. |
| Contract revert | "That can't be done" | Decode the revert reason into a user-readable string. |
| RPC error | "Connection issue" | Retry button; don't leak RPC URL. |
| Timeout | "Still waiting" | Don't crash — show "your transaction is still pending" with a link to the explorer. |

### Decoding reverts

Contracts should emit custom errors:
```solidity
error InsufficientBalance(uint256 required, uint256 available);
error AuctionEnded(uint256 auctionId);
```

Frontend maintains a map:
```ts
const ERROR_MESSAGES: Record<string, (args: unknown[]) => string> = {
  'InsufficientBalance': (args) => `You need ${formatEther(args[0])} ETH; you have ${formatEther(args[1])}.`,
  'AuctionEnded': (args) => `This auction has already ended.`,
};
```

Never show `0x1234...` hex errors to users.

### Pending transaction UX

Users need:
- Confirmation they submitted ("Wallet prompt appeared").
- Confirmation they signed ("Broadcasting your transaction...").
- Tx hash + explorer link immediately after signature.
- Status updates during confirmation ("Block 12 of 15 confirmations").
- Success state with what happened + a next action.
- Failure state with what failed + a recovery path.

Silence between "signed" and "done" feels broken. Fill the gap.

## Wallet integration

See the `reown-appkit-web3` skill for multi-chain setup. Key architectural decisions at the client layer:

### 1. Single or multiple wallet providers?

- **One provider** (e.g. Reown AppKit) — cleanest; covers EVM, Solana, Bitcoin in one SDK.
- **Multiple** — only if you have a reason (e.g. specific wallet integrations Reown doesn't support). More surface area.

### 2. Chain selection UX

- **Show required chain clearly** at the top of the relevant page.
- **Prompt to switch** when user is on the wrong chain — don't silently switch.
- **Persist the user's choice** across sessions.
- **Handle switchover during action** — user signs on chain A, you expected chain B — catch and prompt.

### 3. Reconnection on page load

Most wallets support auto-reconnect. Default to on, but show "not connected" state briefly during reconciliation — avoid flashing "connect" then jumping to the full UI.

## Multi-chain client patterns

If the dApp spans multiple chains:

- **Chain selector** — visible and user-driven.
- **Don't pretend chains are the same** — a USDC on Arbitrum and a USDC on Base are different balances.
- **Transaction context** — every action is tied to a specific chain. Don't let users think they're doing one action across multiple chains.
- **Bridge integrations** — if users need to move assets, integrate a bridge (Squid, LiFi) rather than sending them off-site.

## State architecture — how it fits together

```
────────── Zustand / Redux / NgRx / signals ──────────
  Wallet state (from SDK)        ← reactive
  UI state (modals, forms)        ← local
──────────────────────────────────────────────────────

────────── React Query / TanStack / equivalent ───────
  On-chain reads (from indexer / RPC)  ← cached, invalidated on events
  Transaction status (per-tx)           ← short-lived, not cached
──────────────────────────────────────────────────────

────────── Event listeners (persistent) ──────────────
  Specific contract events user cares about → invalidate matching queries
──────────────────────────────────────────────────────
```

Separation of concerns:
- **Wallet SDK owns wallet state.** Don't duplicate.
- **Query library owns server-cached data.** Don't put it in your global store.
- **Global store owns UI + derived state.** That's it.

Confusion between these three is the #1 client-side architectural mess.

## Performance

### First paint

- **Lazy-load the wallet SDK.** Users looking at the landing page don't need ethers/wagmi yet.
- **Prefetch the main route's data.** Know what the post-connect state looks like; fetch it in parallel with the connection.
- **Inline critical CSS.** Blocked stylesheets delay LCP.

### During session

- **Batched reads** — one `multicall` per page render, not N individual reads.
- **Debounced inputs** — forms submitting on every keystroke are costly if you simulate per stroke.
- **Virtualize long lists.** NFT grids with 10,000 items kill the browser without virtualization.

### Cost

- Public RPCs are rate-limited. Use Alchemy / Infura / QuickNode for production.
- Cache aggressively for read-heavy pages.
- Subgraph first for historical queries; RPC for current state only.

## Accessibility and i18n

Often forgotten in dApp frontends.

- **Keyboard navigation**: connect flow, transaction signing, modals.
- **Screen reader labels**: all interactive elements; dynamic content announced via live regions.
- **Color contrast**: WCAG AA; most dApp dark themes fail this.
- **i18n**: if your audience isn't 100% English, decide early. Retrofit is painful.

## Output of this phase

- [ ] Rendering model decision (SPA / SSR / SSG / hybrid), with reasoning.
- [ ] State architecture diagram: what lives where, who owns what.
- [ ] Error UX map: error category → user-readable message + recovery path.
- [ ] Wallet integration plan: one provider or many, which chains, reconnection behavior.
- [ ] Caching strategy: which data is watched, which is fetched-on-demand, invalidation triggers.
- [ ] Performance budget: first paint target, read cost per page, worst-case list sizes.

Downstream indexing, keepers, and backend components will all consume client requirements. Don't overspec the client before indexing can serve it, or vice versa.
