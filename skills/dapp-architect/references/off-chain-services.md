# Off-chain services

Not every dApp needs a backend. But most eventually do. The question is when, why, and what.

## When you don't need a backend

The pure "only-contracts-plus-frontend" dApp is viable when:

- All state is on-chain.
- All reads can be satisfied by RPC / subgraph.
- All notifications can be handled by the wallet or Etherscan.
- No integrations with non-chain systems (payments, email, push notifications, social).
- No "keeper" work — no time-triggered or condition-triggered automation.

Uniswap v2 comes close to this ideal. If you can stay here, stay here. Less ops, less trust surface.

## When you do need off-chain services

Almost all non-trivial dApps need at least some of these:

| Need | Off-chain service |
|------|-------------------|
| Scheduled actions (resolve auctions, process payouts) | Keeper |
| Event-triggered actions (mint when a condition is met) | Keeper or bot |
| Push notifications (Discord, email, browser push) | Notification service |
| Social features (profiles, comments, likes) | Backend + database |
| Payment processing (credit card, bank transfer) | Backend + Stripe/Circle |
| Off-chain order book or matching engine | Backend + database |
| Image generation, text summarization, any ML | Backend + ML provider |
| Admin operations (moderation, KYC, support) | Backend + admin UI |

Each is a separate service. Combining them into one monolith works for small teams but breaks down.

## The keeper pattern

A **keeper** is an off-chain worker that calls on-chain functions when conditions warrant. Examples:

- **Auction resolver**: every N minutes, check auctions that should end; call `endAuction(...)` for any past their endTime.
- **Payout processor**: after an auction ends, call `claimWinnings` on behalf of the winner (gasless UX).
- **Oracle updater**: push fresh price data to the chain if it's drifted past a threshold.

### Who can run a keeper

- **You** (centralized): simplest, but a single point of failure. If your keeper server dies, auctions don't resolve.
- **Chainlink Automation / Gelato** (decentralized): pay per execution. Reliable. Extra dependency.
- **Anyone with a tip** (permissionless keepers): contract pays a small bounty to anyone who calls the function. Most robust; requires designing the bounty incentive.

### Keeper anti-patterns

- **Keeper that holds user funds**: makes the keeper a trust point that could steal. Keep funds in contracts; keeper only has permission to move them per clear rules.
- **Keeper with unlimited gas**: a bug in your contract could drain the keeper's wallet. Bound keeper's spend per day.
- **Keeper without retry / idempotency**: transactions can fail; the keeper must recover. Track in-flight transactions; retry on revert; don't double-execute.

### Keeper deployment

Simple keeper = a cron job + a wallet:

```ts
// Every 60 seconds:
const activeAuctions = await getActiveAuctions();
const expired = activeAuctions.filter(a => a.endTime < now());
for (const auction of expired) {
  if (!alreadyQueued(auction.id)) {
    queueTransaction(() => contract.endAuction(auction.id));
  }
}
```

Plus observability: alert if the queue backs up, if transactions keep reverting, if the keeper wallet's balance gets low.

## Notification services

Users expect to know when things happen. They won't stare at the app.

### What to notify on

- **User's own transactions**: success / failure (wallet usually handles this).
- **Events relevant to user**: they're outbid, their auction ended, they won a raffle, their staked position earned rewards.
- **Admin events**: contract paused, system maintenance.

### Channels

- **Email**: widest reach; users already share this with everyone. Requires off-chain user-to-email mapping.
- **Push notifications**: browser/mobile. Requires the user to opt in; works without collecting email.
- **Discord / Telegram**: for communities. Requires a bot and user-to-Discord mapping.
- **In-app**: the dApp shows a badge/toast when they return. Simplest; only works while they're using the app.

### Architecture

```
Chain event ─→ Indexer ─→ Notification service
                          │
                          ├─→ email (SendGrid, Postmark, etc.)
                          ├─→ push (VAPID, Firebase)
                          ├─→ Discord bot
                          └─→ in-app toast (WebSocket push)
```

The indexer is usually the trigger source: it sees events, runs "does any user want to know about this?", dispatches.

Pattern: have users register preferences off-chain (email, which events they want notified for). Store in your database. Match events against preferences.

## Backend — when, what, how

A proper backend (REST/GraphQL API + database) is needed when:

- **Off-chain state** is required (profiles, settings, preferences).
- **Privacy-sensitive operations** happen off-chain (draft posts, private messages, internal flags).
- **Heavy computation** off-chain is cheaper (ML, images, aggregations).
- **Admin operations** need a UI and permissioning.

### What goes in the backend database vs on-chain

| Data | Location |
|------|----------|
| Public, user-owned assets | On-chain |
| User preferences (notification settings, UI theme) | Backend DB |
| User profiles (bio, avatar URL) | Backend DB or IPFS-linked on-chain |
| Comments, reactions, social graph | Backend DB |
| Pricing data | Oracle on-chain for trust-sensitive; backend cache for UI |
| Order book (centralized matching) | Backend DB |
| Error logs, analytics | Backend DB |

### Authentication

Web3-native: **Sign-In with Ethereum (SIWE)** or equivalent.

1. User signs a message from the frontend.
2. Backend verifies the signature matches a claimed address.
3. Backend issues a session token (JWT or cookie).
4. Session identifies the user by wallet address.

Use existing libraries (`siwe` for JS). Never roll your own.

### Backend architecture rules

- **Stateless by default**. Horizontal scaling; easy restarts.
- **Health checks**. `/health` endpoint that returns 200 if alive.
- **Observability from day one**. Logs, metrics, traces.
- **Rate limiting**. Every endpoint that hits a database or RPC needs a rate limit.
- **Input validation at the boundary**. Reject obviously-bad inputs before they hit business logic.
- **Never trust user-supplied addresses without verifying signature**. If the user claims "I'm 0xabc...", require them to prove it.

### Backend + chain interactions

- **Read**: backend reads chain via RPC or subgraph, caches results, serves to client.
- **Write**: backend signs transactions for specific operations (keeper, meta-transactions).
- **Sync**: backend subscribes to events, updates its own database when chain changes.

A common pattern: backend maintains a "materialized view" of chain state — denormalized, queryable by any client, updated on every event.

## Payment processing (fiat)

If accepting fiat (credit card → on-chain action):

- Use Stripe or equivalent for the payment side. Don't try to build a card processor.
- Backend receives Stripe webhook on successful payment.
- Backend triggers the on-chain action (via keeper).

See the `stripe-subscription-lifecycle` skill for webhook handling specifics.

## Social / community integrations

For dApps with a Discord / Telegram / X presence:

- **Discord bot**: slash commands for common dApp actions, role assignment based on on-chain holdings, event announcements.
- **Telegram bot**: similar, for regions where Telegram dominates.
- **X automation**: post announcements on key events (via API).

Build on existing infrastructure (bocto-style bot) rather than reinventing.

## AI/LLM integrations

If the dApp uses an LLM somewhere:

- **At design time (admin)**: user-initiated, rare. Low cost.
- **At runtime (user-facing)**: every call costs money. Budget carefully.
- **For narrative / descriptions**: can be precomputed at design time and cached. Prefer this.
- **For live chat / customer support**: scales by traffic. Plan quota.

Never put an LLM in the critical path of a transaction. Users will hit it; bugs will compound; cost will surprise.

## The "ops tax"

Every off-chain service is ongoing ops work:
- Monitoring and alerting.
- Patching and updates.
- Scaling.
- Incident response.
- Cost monitoring.

Each additional service is roughly 1/4 person's attention. Budget accordingly. Two engineers can't sustain ten services.

Prefer:
- **Fewer, larger services** over many small ones (in early stage).
- **Managed services** (AWS Lambda, Cloudflare Workers, Vercel Functions, managed Postgres) over self-hosted.
- **Proven stacks** over exotic tech.

## Output of this phase

- [ ] Decision per capability: backend / keeper / notification / social / payment — needed? yes/no/later?
- [ ] For each "yes": architecture sketch, hosting choice, who operates it.
- [ ] Auth decision: SIWE / custom / both?
- [ ] Database choice: Postgres / Mongo / Redis, with reasoning.
- [ ] Dependency list of third-party services (Stripe, SendGrid, etc.) with cost estimates.
- [ ] Keeper infrastructure: centralized / Chainlink / Gelato / permissionless. Bounty math if applicable.
- [ ] Notification strategy: channels, opt-in flow, message design.
