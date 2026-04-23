# Trust boundaries

Who is trusted with what. This map drives every downstream architecture decision. Get it wrong and the dApp is either insecure or uselessly decentralized.

## The four domains

Every dApp has at least four domains where trust is distributed differently:

1. **The user's wallet** — fully under user control. Signs transactions, holds funds.
2. **The chain** — trustless. Rules are code; what's on-chain is canon.
3. **The operator's infrastructure** — servers, RPC endpoints, keepers, subgraphs. Trusted by users with availability + integrity of data relay.
4. **Third parties** — oracles, external services (payment gateways, identity providers, LLM APIs). Each has its own trust assumptions.

For every piece of state and every action, ask: which domain owns it? Who can forge it? Who can censor it?

## The on-chain/off-chain decision tree

Every piece of state belongs in one place:

| Property | Goes on-chain if... | Goes off-chain if... |
|----------|---------------------|----------------------|
| Ownership of an asset | User-owned and liquid | Internal system state |
| Transactional state | Needs trustless enforcement | Needs speed or privacy |
| Configuration | Users need to verify it | It's an admin preference |
| Historical data | Users care about permanence | It's just a convenience |
| Identity | Part of on-chain reputation | Convenience-only profile |
| Heavy data (images, long text) | Almost never (use IPFS/Arweave pointer) | Almost always |

Cost is part of the decision:

- A CRUD-style database entry on-chain is ~50,000 gas. On mainnet at 30 gwei that's ~$5 every time. On an L2 it's ~$0.05.
- Off-chain is effectively free per operation but requires running a backend that must stay up.

## The trust-boundary map

Produce this diagram for every dApp:

```
USER WALLET (user trusts)
    │
    │ (signs tx)
    ▼
──────── trust boundary ────────
    │
    ▼
CHAIN (trustless)
    ├── reads ────────→ INDEXER (operator trust: availability + data integrity)
    ├── reads ────────→ RPC PROVIDER (operator trust: availability)
    └── events ───────→ KEEPER (operator trust: triggers on-chain actions when it should)
                            │
                            ▼
                       BACKEND (operator trust: data integrity, access control)
                            │
                            ├── OFF-CHAIN DB (operator controls)
                            └── THIRD PARTY (e.g. payment, oracle, LLM)
```

Every arrow is a trust relationship. Label each: what does the upstream trust the downstream for? Availability? Integrity? Privacy? Non-censorship?

## Centralization rights

Enumerate every privileged action the operator can take:

- Pause the contract?
- Upgrade the contract?
- Mint additional supply?
- Freeze user funds?
- Change fee rates?
- Update oracle addresses?
- Blacklist addresses?
- Recover stuck funds?

For each, answer:
- **Who holds the key** — EOA, multisig, timelock, DAO, none?
- **How users know it's safe** — audit, reputation, public key disclosure, timelock delay?
- **What happens if the key is lost or compromised** — replacement procedure, insurance, game over?

This becomes part of the spec. Users have a right to know what you can do to their funds.

## Custody vs non-custody

Two very different dApp shapes:

### Non-custodial (preferred default)

User's assets never leave their wallet except for the specific transactions they sign. Examples: Uniswap, OpenSea, ENS.

- **Easier regulatory posture** — you're not handling funds.
- **Higher user control** — we can't rug them.
- **Less engineering burden** — no custody infrastructure.
- **UX tradeoff** — users pay gas, users sign every action.

### Custodial (or hybrid — custodial for internal ops, non-custodial for user assets)

Platform holds user funds in a shared or per-user vault. Examples: some casinos, sponsored-gas meta-tx systems, tipping bots.

- **Better UX** — fewer signatures, gasless actions, instant operations.
- **Huge operational burden** — you're a bank.
- **Regulatory exposure** — money transmitter laws, KYC depending on jurisdiction.
- **Security risk** — you're a target. A breach can move millions.
- **Recovery risk** — if your encryption key (e.g. `WALLET_SECRET`) is lost, every custodial wallet is permanently gone.

If going custodial, every primitive needs hardening: key rotation, per-wallet salts, audit trail, withdrawal rate limits, access control by role (admin can fund but not withdraw), treasury-vs-user-funds separation.

## Privileged roles — design with care

Any admin / owner / treasurer role has outsized power. Three anti-patterns:

1. **Single EOA owner**. One compromised laptop and the protocol is gone. Use a multisig (Safe) from day one.
2. **Upgradeable without timelock**. Admin can swap the implementation instantly — users can't react. Timelock (e.g. 48h) forces public visibility.
3. **One role that does everything**. Split into: `PAUSER_ROLE`, `UPGRADER_ROLE`, `MINTER_ROLE`. Use AccessControl; scope each role to its minimum.

Good pattern:

```
DEFAULT_ADMIN_ROLE → multisig (3-of-5) → can grant/revoke other roles, gated by timelock
UPGRADER_ROLE → multisig → can upgrade, gated by timelock
PAUSER_ROLE → can be a hot wallet → immediate action in emergency, can only pause
MINTER_ROLE → specific contract (Minter factory) → tightly scoped, no human holds it
```

## Third-party trust

External dependencies are trust boundaries you don't control.

- **RPCs** (Alchemy, Infura, Ankr, public nodes) — trust them with availability and non-censorship. Mitigate by fallback provider.
- **Oracles** (Chainlink, Switchboard, custom) — trust them with data integrity. Mitigate by multiple oracle sources + outlier rejection.
- **Bridges** — trust them with cross-chain transfers. Common attack surface. Prefer canonical over generic.
- **IPFS / Arweave** — trust with persistence. Use pinning services; keep local copies of critical metadata.
- **LLM APIs** — if you use one, it can go down or change behavior. Prefer pre-scripted over LLM for critical paths.
- **Stripe / payment gateways** — trust with payment processing. Standard risk.

For each, plan for: outage, price increase, malicious behavior, policy change (e.g. "service no longer available in country X").

## The "what if operator disappears" test

A useful stress test: what if the team behind the dApp vanishes? Can users recover their assets?

- **Fully decentralized**: users can still withdraw, trade, claim. No operator needed. (Example: Uniswap v2 contracts — still functional even if Uniswap Labs disappears.)
- **Partially operator-dependent**: users can withdraw via a direct-contract-call fallback, but the UI is gone. Requires users to know how to interact with raw contracts.
- **Operator-dependent**: users cannot recover without the operator. The platform is a pseudo-decentralized SaaS.

Know where your dApp falls. Be honest with users. "Censorship-resistant" has a specific meaning — don't claim it if the app falls apart when your frontend is taken down.

## Anti-pattern: the "we'll secure it later" dApp

Signs:
- Admin key is a hot wallet with no multisig.
- Contract is upgradeable without timelock.
- All funds in one pooled vault with simple permissions.
- Single RPC endpoint hardcoded.
- Subgraph pointed at a personal Alchemy key.

This works until it doesn't. Build security into the architecture from day one. Retrofitting is 10x more expensive than doing it right.

## The output

At the end of this phase, you should have:

- [ ] A diagram (Excalidraw, Whimsical, plain Mermaid) showing every trust boundary.
- [ ] An explicit list of operator-privileged actions + who holds each key.
- [ ] A custody model decision (non-custodial / custodial / hybrid) with reasoning.
- [ ] A "what if operator disappears" scenario answered honestly.
- [ ] A list of third-party dependencies + mitigation for each.

Everything downstream — contracts, client, indexing, ops — inherits from this map. Do it well or pay later.
