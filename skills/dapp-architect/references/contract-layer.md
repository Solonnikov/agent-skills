# Contract layer

Contracts are the hardest part of a dApp to change. Get the shape right up front; polish implementations later. This is about composition and interfaces, not line-by-line Solidity.

For Solidity scaffolding basics, see the `evm-contract-scaffold` skill. This reference covers how contracts relate to each other and to the rest of the system.

## Start with the interfaces

Before any implementation, sketch the public surface of every contract: what functions users call, what events emit, what state is readable.

```solidity
interface IAuction {
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    event AuctionWon(uint256 indexed auctionId, address indexed winner, uint256 amount);
    event AuctionCanceled(uint256 indexed auctionId);

    function placeBid(uint256 auctionId) external payable;
    function claimWinnings(uint256 auctionId) external;
    function cancelAuction(uint256 auctionId) external;

    function getAuction(uint256 auctionId) external view returns (Auction memory);
    function getActiveAuctions() external view returns (uint256[] memory);
}
```

Benefits:
- Forces clarity before code.
- Frontend and indexer can start work in parallel once interfaces exist.
- Review the surface area for attack and abuse before anyone writes `require(msg.sender == owner)` in 50 places.

## Monolithic vs modular

### Monolithic — one big contract

Fewer deploy steps. Cheaper for users (less CROSS-contract calls). Easier to reason about for a small app.

**When to choose:** single-purpose dApp, small team, low chance of feature growth, one chain.

### Modular — separate concerns into distinct contracts

Core + periphery pattern. Example: `Core` (asset custody + business logic, rarely changed) + `Router` (UX helpers + batch operations, upgradeable).

**When to choose:** complex system, multiple developers, need to swap pieces independently, expect upgrades.

### Factory + registry pattern

One `Factory` deploys per-entity `Instance` contracts; a `Registry` tracks which exist.

**Example:** `CasinoFactory.createCasino(...)` → deploys a new `Casino` → registered in the `Factory`.

**When to choose:** per-user/per-community/per-asset instances, no global shared state, need isolation between instances.

This is bocto/octopeeps territory — each server, NFT collection, or game gets its own contract instance.

## Upgradeability — the cost/benefit call

**Default immutable.** Upgradeable is a cost:
- Storage layout must be managed (never reorder or change variable types; append only).
- Initializers instead of constructors.
- Timelock + multisig governance on upgrades (otherwise users have no protection).
- Audit on every upgrade.
- Upgrades can introduce bugs in production.

**Opt into upgradeable when:**
- The problem space is genuinely unclear — you'll learn from users.
- Regulatory or legal changes might force a pivot.
- Integrations with other protocols are moving fast.

**Proxy patterns:**
- **UUPS** (preferred) — upgrade logic in the implementation, slimmer proxy.
- **Transparent** — older pattern, heavier proxy.
- **Beacon** — one upgrade point for many proxies (factory pattern, same implementation for all instances).
- **Diamond (EIP-2535)** — for very large contracts. Rarely justified. Complex to audit.

Use OpenZeppelin's upgradeable package + their Hardhat/Foundry upgrades plugin. Never hand-roll a proxy.

## Storage decisions

### What to store on-chain

- **User-owned asset state** — balances, ownership, allowances.
- **Protocol rules** — fees, parameters users verify.
- **Invariants** — supply caps, timing constraints.
- **Pointers to off-chain data** — IPFS hashes, oracle addresses, URIs.

### What NOT to store on-chain

- **Heavy data** — images, videos, long text. Use IPFS/Arweave; store the hash.
- **User PII** — email, name, phone. Even if encrypted, it's on-chain forever.
- **Frequently-changing state** that doesn't need trustlessness — analytics counters, UI state.
- **State you could compute from events** — redundant; indexers derive this.

### State you can compute from events

A powerful pattern: emit rich events, keep on-chain state minimal.

```solidity
// Instead of storing every bid:
mapping(uint256 => Bid[]) public allBids; // expensive

// Emit events and let the indexer reconstruct:
event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount, uint256 timestamp);
// On-chain state is only the highest bid. Historical bids live in the subgraph.
```

Gas savings compound; indexing becomes the source for historical queries.

## Events — design first

Indexers, bots, and frontends consume events. Bad event design cascades across all of them.

### Event design rules

- **Emit for every state change** that anyone off-chain cares about. When in doubt, emit.
- **Index (`indexed` keyword) on fields consumers filter by** — addresses, IDs, enums. Max 3 indexed per event.
- **Include enough context** that a consumer reading the event alone can understand what happened. Don't force them to re-read contract state.
- **Include timestamps** — block timestamp, for analytics/UX. (Yes, the block has this, but inline makes consumers' lives easier.)
- **Version-namespace events** if you anticipate breaking changes: `BidPlacedV2`.

### Events you always want

- **`OwnershipTransferred`** (from Ownable) — for admin tracking.
- **`RoleGranted` / `RoleRevoked`** (from AccessControl).
- **`Paused` / `Unpaused`** (from Pausable).
- **Per-flow `Started` / `Completed` / `Failed` triad** — for auctions, redemptions, swaps. Lets you compute pending state.

### Event anti-patterns

- **Emitting once per batch** when consumers want per-item detail. Emit per-item.
- **Packing multiple semantic events into one** with an enum. Separate events are clearer.
- **Emitting after external calls** — reentrancy risk. Emit before the state change settles.

## Interfaces between contracts

When `ContractA` calls `ContractB`:

- **Use interfaces**, not full contract imports. Lighter compile, clearer coupling.
- **Check return values** — `IERC20.transfer` returns bool; failing to check is a classic bug.
- **Prefer `safeTransferFrom` / `SafeERC20`** over raw calls — handles non-conforming tokens.
- **Consider what happens if `ContractB` is upgradeable and changes its interface.** Pin the version or add a fallback.

## Integrating external protocols

Every external integration is a trust boundary. Before building on another protocol:

- **Is the contract audited?** By whom? Recent?
- **Is it upgradeable? Who controls upgrades?**
- **Does it have a history of exploits?**
- **Does it have a TVL floor that matters to your users?**
- **Is there a fallback if it goes offline or malicious?**

Common integrations and their gotchas:
- **ERC-20s**: not all tokens conform. USDT doesn't return bool. Some are fee-on-transfer. Some are rebasing. Use `SafeERC20`; test against weird tokens.
- **Uniswap**: V2 vs V3 vs V4 — each has a different interface and semantics.
- **Chainlink oracles**: watch for stale prices; check heartbeat.
- **ENS / other naming**: watch for expired names resolving to different addresses.

## Factory + per-entity pattern (octopeeps / bocto shape)

For dApps with per-user or per-entity state (NFT collections, casinos, Discord servers, stores):

```solidity
// Factory — deployed once
contract CollectionFactory {
    address[] public collections;
    event CollectionCreated(address indexed owner, address collection, uint256 index);

    function createCollection(string memory name, string memory symbol) external returns (address) {
        NFTCollection c = new NFTCollection(msg.sender, name, symbol);
        collections.push(address(c));
        emit CollectionCreated(msg.sender, address(c), collections.length - 1);
        return address(c);
    }
}

// Per-entity — one per creator
contract NFTCollection is ERC721, Ownable {
    constructor(address initialOwner, string memory name, string memory symbol)
        ERC721(name, symbol)
        Ownable(initialOwner)
    {}
    // ...
}
```

Benefits:
- Each collection is isolated. One creator's bug doesn't brick everyone.
- Different owners can have different parameters.
- Easier to deprecate one instance without touching others.

Costs:
- More contracts deployed (more audit surface, though usually the implementation is the same).
- Gas per-instance creation (use minimal proxy / EIP-1167 to cut cost).
- Clients need to discover instances (factory emits events; indexer tracks them).

This is the pattern octopeeps uses for its checkers + badges; slots uses it for per-casino isolation.

## Output of this phase

- [ ] Interface files (or TypeScript-style interface specs) for every public contract.
- [ ] A decision: monolithic vs modular vs factory pattern, with reasoning.
- [ ] An upgradeability decision: immutable / UUPS / beacon / transparent / diamond, with reasoning.
- [ ] Event specification: what events fire, which fields are indexed, what consumers will use them for.
- [ ] A list of external protocols being integrated, with audit + risk notes on each.
- [ ] A rough size estimate: bytes per contract, gas per common operation — to catch gas-budget problems before deploy.

Downstream — client layer, indexing, backend — all inherit from these decisions. Revise as needed when downstream surfaces constraints; don't plow ahead if you hit one.
