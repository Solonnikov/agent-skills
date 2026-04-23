# Deployment + ops

Shipping a dApp doesn't end at mainnet deploy. Ops is where dApps live (or die). Plan the full lifecycle, not just launch day.

## The deployment pipeline

A standard progression:

```
Local (anvil/hardhat network) ─→ Testnet ─→ Mainnet beta ─→ Mainnet GA
    dev                           staging      early users     public
```

Each stage has a different purpose.

### Local

- Fast iteration. `anvil`/`hardhat node` forks mainnet for realistic testing.
- Instant deploys. No gas costs. Reset state as needed.
- CI runs every PR against local.

### Testnet

- **Sepolia (Ethereum)** — default Ethereum testnet.
- **Base Sepolia**, **Arbitrum Sepolia**, **Optimism Sepolia**, **Polygon Amoy** — L2 equivalents.
- **Solana Devnet** — for Solana programs.

Use for:
- Integration testing with real wallets.
- External parties (indexers, bots) testing against a real RPC.
- Beta users signing up before mainnet.

Don't use for:
- Final performance tests (testnet is less congested than mainnet).
- Economic tests (no real money at stake; behavior differs).
- Proof-of-security (testnet doesn't have MEV or serious adversaries).

### Mainnet beta

A staged production launch. Recognizable from regular mainnet only by:
- Lower volumes / caps initially.
- Clear "beta" labeling in the UI.
- Tighter monitoring + on-call rotation.
- Easier rollback path (circuit breaker armed, smaller blast radius).
- Allowlist or invite-gated users.

Most teams skip this stage. Don't. It's the only environment where you see real adversaries, real MEV, real RPC wobbles. 2–4 weeks minimum.

### Mainnet GA

Open to everyone. Full marketing push. Expected post-launch issues handled via the observability + runbooks you built in the prior stages.

## Deploy sequencing

A typical deploy of a multi-contract dApp:

1. **Deploy infrastructure contracts first** (e.g. Factory, Registry).
2. **Deploy implementations** (for proxy patterns).
3. **Deploy proxies pointing at implementations**.
4. **Initialize** each contract with configuration.
5. **Grant roles** (admin, minter, etc.) — ideally directly to multisig, not EOA.
6. **Verify on Etherscan** — immediately; cold verifications are harder.
7. **Update frontend config** with deployed addresses.
8. **Deploy subgraph** / configure indexer to start from the deploy block.
9. **Deploy backend** with new contract addresses + ABIs.
10. **Deploy frontend** — last, so users can't interact before the backend is ready.

Scriptify every step. Manual deploys fail on the most important nights.

## Multi-chain deployment

If shipping to multiple chains:

- **Same contract address across chains?** — possible via deterministic deploy (CREATE2 + same deployer nonce). Not always worth the hassle.
- **Different addresses per chain?** — the normal case. Keep a `deployments/<chain>.json` mapping.
- **Contract code identical across chains?** — yes, unless a chain has different opcodes (e.g. zkSync's different create2).
- **Sequence**: deploy to testnet of each chain → deploy to mainnet of each chain. Don't mix (testnet of chain A, mainnet of chain B) — creates deployment chaos.

Every extra chain doubles ops work. Only add chains for real user need, not marketing.

## Verification

Every deployed contract gets verified on its explorer. See the `hardhat-etherscan-verification` skill for details.

Best practices:
- Verify as part of the deploy script; don't leave it for "later."
- If verification fails, fix immediately. Unverified contracts signal "not serious."
- Keep source code in the repo; tag the commit that matches each deployment.

## Upgrade lifecycle

If the contracts are upgradeable:

### Before the upgrade

- **Storage layout compatibility check** via OpenZeppelin's upgrade tools (Foundry or Hardhat plugins).
- **Dry-run**: test the upgrade against a mainnet fork.
- **Audit** if the change is non-trivial.
- **Timelock queue** the upgrade (e.g. 48h window before it can execute).
- **Announce publicly** with details of what's changing.

### During the upgrade

- **Execute from the multisig** with the quorum of signers.
- **Monitor the first transactions** after the upgrade — any reverts that weren't happening before?
- **Have the rollback ready** (previous implementation address + steps to downgrade).

### After the upgrade

- **Re-verify** on Etherscan.
- **Update the deployments log** with new implementation address.
- **Communicate what's live.**

### Emergency upgrade

If an exploit is in progress: pause first (if the contract supports it), then plan the fix calmly. Don't deploy a hotfix in 10 minutes — it's how second exploits happen.

## Observability

The first thing to build; ship with v0.1, not v1.0.

### Minimum instrumentation

**On-chain (via indexer/subgraph):**
- Daily transaction count per contract.
- Revert rate — transactions that failed, grouped by revert reason.
- Gas cost per common operation (detect if it drifts up).
- Unique users per day.
- Total value locked (for any contract holding funds).

**Client-side:**
- Error rate (JavaScript exceptions, chain call failures).
- Transaction simulation failure rate (indicates the contract is rejecting valid-looking inputs — a sign of degradation).
- Wallet connection success rate.
- First-meaningful-paint latency.

**Backend:**
- Request rate and latency per endpoint.
- Database query latency.
- Queue depth for any async work.
- Error rate.

**RPC / subgraph:**
- Query latency p50 / p95.
- Error rate.
- Indexer lag (how many blocks behind head).

### Alerts

Only alert on things where the response is "someone wakes up and does something." If there's no action, it's a metric, not an alert.

Good alerts:
- Revert rate on a critical function > 5% over 10 min.
- Indexer lagging > 50 blocks for > 15 min.
- RPC error rate > 20% for > 5 min.
- Backend error rate > 1% for > 5 min.
- Treasury balance below a safety threshold.

Bad alerts (noise):
- "Someone used the contract."
- "A transaction reverted." (Without rate context, this is every single user rejection — normal.)
- "Gas price is high." (This is the ecosystem, not you.)

### Dashboards

Separate dashboards for:
- **Ops**: is it working? Fast answers during incidents.
- **Product**: are people using it? How much?
- **Finance**: is the treasury / cost profile healthy?

Pin them; link them from the runbook.

## Runbooks

For each likely incident, a written playbook.

### The "contracts are reverting" runbook

```
SYMPTOMS
- Revert rate on [contract] above 5% for >10 min.
- User reports of "transaction failed" in Discord.

FIRST 5 MINUTES
- Check monitoring dashboard: which function is reverting most?
- Check recent deploys: anything went out in the last 24h?
- Check dependent contracts: did an oracle change? A third-party contract upgrade?

FIRST 30 MINUTES
- Review revert reasons — is it always the same error?
- Reproduce locally against mainnet fork.
- If confirmed bug: pause the contract (if possible); announce in #status channel.

RECOVERY
- Deploy fix following upgrade process (or hotfix deploy if immutable).
- Unpause.
- Post-mortem within 48h.
```

Each likely incident has one. Living documents. Updated after every real incident.

### The "RPC is down" runbook

```
SYMPTOMS
- Frontend unable to read on-chain state.
- Backend transaction submissions failing.

FIRST 5 MINUTES
- Check RPC provider's status page.
- Check fallback RPC health.
- Confirm the issue is RPC, not our code.

RESPONSE
- If fallback RPC is healthy: failover (should be automatic).
- If all RPCs down: communicate via Discord/X. Users can't do anything; we can't either.
- Update frontend to show a maintenance message if outage is > 30 min.
```

### The "exploit in progress" runbook

Pre-write this one. If it's your first time thinking about it at 3am, it's already too late.

```
SYMPTOMS
- Unexpected large withdrawal.
- Alert on treasury balance drop.
- User reports of "my funds moved."

FIRST STEP
- Pause the contract. RIGHT NOW. Discussion comes after.
- Any admin who can pause: do it.

NEXT 30 MINUTES
- Convene the multisig signers.
- Read transaction traces.
- Confirm or disconfirm exploit.
- If confirmed: prepare communication. Do not say "everything is fine."
- If not confirmed: unpause.

RECOVERY PLAN
- If funds recoverable: coordinate with security firm, potentially recovery via WhiteHat.
- If funds not recoverable: calculate loss, plan compensation, announce transparently.
```

## Communication channels

Pre-establish:
- **Status page** — public, updated in incidents.
- **Announcement channel** — Discord / Telegram / X — where you post updates.
- **On-call rotation** — who responds first at what time.
- **Escalation chain** — who gets woken up if first responder can't resolve.

## Costs

Budget approximately:

- **RPCs**: $100-1,000/mo depending on scale.
- **Subgraph / indexer**: $0-300/mo for hosted; more for decentralized or custom.
- **Backend**: $50-500/mo for hosting + DB + auxiliary services.
- **Monitoring/alerting**: $50-200/mo (Datadog, Sentry, Grafana Cloud).
- **Email / notification**: $30-200/mo.
- **Keeper gas**: varies — $50-5,000/mo depending on call frequency and gas price.
- **Multisig / key management**: mostly one-time setup.

Have a burn rate and runway for ops. Running out of gas on a keeper is a preventable outage.

## The go-live checklist

Before mainnet GA:

- [ ] All contracts deployed, verified, and governance transferred to multisig.
- [ ] Subgraph/indexer synced to head; verified queries return expected data.
- [ ] Backend deployed with health checks passing.
- [ ] Frontend deployed with contract addresses matching deployment log.
- [ ] Observability dashboards live, ops team has access.
- [ ] Alerts wired to pager / Slack / email, on-call rotation started.
- [ ] Runbooks written for top 5 likely incidents.
- [ ] Status page live, communication channels ready.
- [ ] Treasury / keeper wallets funded with enough runway for 30 days.
- [ ] Incident response playbook practiced (at least a tabletop exercise).

## Post-launch

- **Weekly review**: what went wrong, what went right, what to improve.
- **Monthly dashboards review**: is usage growing? Are costs in line?
- **Quarterly architecture review**: is the architecture still serving the product, or is there drift?

A dApp is a living system. Ops is not a phase; it's the permanent state of the system after launch.

## Output of this phase

- [ ] Deploy scripts for each environment (local, testnet, mainnet), idempotent and scripted.
- [ ] A deployments log (`deployments/<chain>.json`) with addresses, block numbers, commit hashes.
- [ ] Observability stack: metrics, dashboards, alerts, error tracking.
- [ ] Runbooks for the top ~5 incident classes.
- [ ] Communication channels live (status page, announcement channel).
- [ ] On-call rotation established.
- [ ] Mainnet-beta plan, including go/no-go criteria for GA.
- [ ] Budget / runway forecast for at least 6 months of ops.

If you can't tick every box, you're not ready for mainnet GA. Push the date.
