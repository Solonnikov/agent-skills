# Indexing + events

Reading on-chain state is harder than writing it. Getting indexing right is often the difference between a snappy dApp and one that feels perpetually stuck.

## The question to answer first

**How does the client get the data it needs?**

Three options. Most dApps end up using all three for different purposes:

1. **Direct RPC** (read from a node via wagmi / ethers / viem).
2. **Subgraph** (The Graph or hosted equivalent — query indexed event data via GraphQL).
3. **Custom indexer** (your own worker that ingests events into your own database).

Pick per use case.

## When to use direct RPC

- **Current state**: "what's the user's balance right now?" — RPC is the source of truth.
- **Simple reads**: single account, a few contracts. No cross-referencing.
- **User-triggered reads**: "when the user opens this page, fetch their position."

**Don't use for:**
- Historical queries going back more than a few hundred blocks.
- Aggregations ("total volume in the last 7 days").
- Lists with pagination ("show me all NFTs, sorted by price").

### Batching

Use `multicall` (Multicall3 is deployed on most chains):

```ts
const results = await publicClient.multicall({
  contracts: [
    { address: tokenA, abi, functionName: 'balanceOf', args: [user] },
    { address: tokenB, abi, functionName: 'balanceOf', args: [user] },
    { address: tokenC, abi, functionName: 'balanceOf', args: [user] },
  ],
});
```

One RPC call instead of three. Wagmi's `useReadContracts` hook does this automatically.

### Fallback RPCs

Production RPC endpoints fail. Always have a fallback:

```ts
const transports = fallback([
  http('https://alchemy-url'),
  http('https://infura-url'),
  http('https://ankr-url'),
], { rank: true });
```

Rank mode prefers the fastest responding endpoint; falls over automatically on error.

## When to use a subgraph

- **Historical event data**: "all bids on this auction over the last month."
- **Aggregations**: "total volume per day."
- **Complex queries**: joining, filtering, sorting by fields the contract doesn't index.
- **Pagination**: "page 47 of NFT listings, sorted by price ascending."

Subgraphs are the right default for most dApps. The Graph's hosted service is free for basic usage; decentralized Graph nodes run on a billable basis.

### Subgraph design rules

- **Entities mirror the real-world thing**, not the event. An `Auction` entity persists across many `BidPlaced` events.
- **Denormalize for queries.** Store `totalBids`, `highestBid`, etc. on the `Auction` entity rather than computing from children on every query.
- **Timestamps are first-class.** Every entity has `createdAt`, `updatedAt` — clients rely on them for sorting.
- **Derived fields.** Fields like "isActive" that are computed from other fields + block timestamp.

### Subgraph pitfalls

- **Reorg handling**: The Graph reorganizes when a chain reorgs. Your queries return old data briefly. Usually fine; rarely a problem for mainnet.
- **Indexing lag**: a subgraph isn't instant. It's typically a few blocks behind head. For "current state," use RPC; for anything else, subgraph is fine.
- **Deploys**: schema changes require redeploying from block zero (slow) or from a checkpoint (partial). Plan the initial schema carefully.
- **Starting block**: always start from the contract's deploy block, not from block zero. Saves hours to days of initial indexing.

### Hosted vs decentralized

- **Hosted (The Graph's central service)**: free, easy, but deprecated for many chains.
- **Decentralized (The Graph Network)**: real-money billing, permissionless, production-ready.
- **Self-hosted**: run your own Graph Node. More ops work, full control, usable for chains not on The Graph Network.

## When to use a custom indexer

- **Chain isn't on The Graph** or major hosted alternatives.
- **Aggregation needs** that don't fit the subgraph model (e.g. heavy joins across many contracts).
- **Enrichment** — combine on-chain events with off-chain data (pricing, user profiles, social signals).
- **Real-time subscriptions** — subgraphs poll; a custom indexer can push via websockets.

Modern tooling: Ponder (TS), Envio, Shovel, Rindexer. Roll-your-own with ethers + a database works but is more work.

### Custom indexer architecture

```
Chain events ─────→ Indexer process ─────→ Database
                                            │
                                            ▼
                                       API layer (REST/GraphQL/WS)
                                            │
                                            ▼
                                       Client
```

Key decisions:
- **Database**: Postgres for most use cases; ClickHouse for analytics-heavy.
- **Reorg handling**: rewind and re-ingest when the chain reorgs; most tools handle this.
- **Backfill strategy**: for historical events, start from contract deploy block and process forward.
- **Failure recovery**: checkpointing — save position every N blocks so you can resume.

## Event design for indexers (recap)

From the contract-layer reference, but worth re-stating:

- Emit for every state change downstream consumers care about.
- Index fields clients filter by (max 3 indexed per event).
- Include enough context that the event alone tells the story.
- Consistent event naming (`BidPlaced`, `AuctionEnded`, not `NewBid`, `AuctionDone`).

Example — good event design for indexing:

```solidity
event AuctionCreated(
    uint256 indexed auctionId,
    address indexed seller,
    address indexed tokenContract,
    uint256 tokenId,
    uint256 reservePrice,
    uint64 startTime,
    uint64 endTime
);
```

Subgraph can immediately create an `Auction` entity with all needed fields. No second RPC call to fetch "the rest" of the auction data.

## The "current state" boundary

Be explicit about which data source is authoritative for what:

| Data | Source | Why |
|------|--------|-----|
| User's current balance | RPC | Must be current. |
| "Is the auction still open?" | RPC or subgraph with block context | Depends on timing needs. |
| Auction history (all bids) | Subgraph | Historical, RPC can't do it efficiently. |
| User's transaction history | Subgraph or wallet-facing API | Too expensive via RPC. |
| NFT metadata | HTTP (IPFS gateway) | Not on-chain. |
| Price feed | Oracle via RPC | Current, trusted. |

Clients should know which source is authoritative. If a user sees "balance: 100" from the subgraph (1 block stale) and then tries to swap 99 that's actually 98 on-chain, they get a revert. Fall back to RPC for last-mile checks before signing.

## Real-time updates

How does the client know something changed?

### Pattern 1: Polling

Client re-fetches every N seconds. Simple; works. Costs RPC/subgraph calls.

### Pattern 2: Block-based polling

Listen for new blocks; re-fetch only when a block arrives.

```ts
publicClient.watchBlockNumber({
  onBlockNumber(blockNumber) {
    queryClient.invalidateQueries({ queryKey: [...] });
  },
});
```

### Pattern 3: Event-driven

Subscribe to specific events; re-fetch on match.

```ts
publicClient.watchContractEvent({
  address: auctionContract,
  abi,
  eventName: 'BidPlaced',
  args: { auctionId: currentAuctionId },
  onLogs: () => queryClient.invalidateQueries({ queryKey: ['auction', currentAuctionId] }),
});
```

Event-driven is the most efficient but requires one subscription per watched entity. For dashboards watching many things, a custom indexer with WebSocket push is cleaner.

### Pattern 4: Subgraph polling

The Graph exposes `_meta { block { number } }` — you can poll to see if new blocks have been indexed, then refetch.

## Historical queries — backfill considerations

- **Start from contract deploy block.** Using block 0 is wasted computation.
- **Chunk batch reads.** `eth_getLogs` has a max block range (commonly 10,000). Paginate with a loop.
- **Rate limit.** Your RPC provider will throttle you; add backoff.
- **Checkpoint frequently.** If indexer crashes at block 1,000,000, restart from block 999,500 not 0.
- **Don't re-index** on every deploy. Reuse data from previous runs wherever possible.

## Cost considerations

### RPC costs

- **Alchemy/Infura free tiers**: good for development, throttled for production.
- **Production**: budget $100-500/mo for a moderate dApp.
- **Heavy reads** (historical, analytics): budget can blow up fast. Use a subgraph or custom indexer instead.

### The Graph costs

- **Hosted**: free.
- **Decentralized**: ~$10-50/mo for moderate query volume; gets expensive at scale.
- **Self-hosted**: server costs + dev time.

### Custom indexer costs

- Hosting (~$20-100/mo).
- Database (~$20-200/mo depending on data volume).
- Ops time.

Usually custom indexer is the cheapest at scale, most expensive to build and maintain.

## Output of this phase

- [ ] Decision: RPC-only, subgraph, custom indexer, or hybrid — per data domain.
- [ ] Event specification reviewed against indexing needs. Any missing fields? Any bad indexing?
- [ ] If subgraph: schema sketch, entity relationships, query patterns.
- [ ] If custom indexer: database choice, reorg handling, backfill plan.
- [ ] RPC provider shortlist + fallback chain.
- [ ] Real-time update pattern: polling / block / event / push.
- [ ] Cost estimate per data source.

Getting this layer right makes the client snappy; getting it wrong makes every page loader spin.
