# Brief → spec

The architect's first deliverable. A brief is a document a sane engineer could estimate, a sane user could validate, and a sane investor could understand. Most dApp projects fail architecturally because they skip this and jump to Solidity.

## The spec template

```markdown
# <dApp name> — spec v<date>

## Problem
[One sentence. The actual user pain. Not "we'll use blockchain" — that's a solution.]

## Target user
- Who they are (personas, skill level, wallet use).
- What they currently do instead.
- What we believe they'd pay for (money, attention, data).

## Proposed solution
[Two to four sentences. The core loop: user arrives → does X → receives Y. No tech stack yet.]

## Why blockchain
[Honest answer. If the system would work the same as a centralized SaaS, cut blockchain. Blockchain wins for: user-owned assets, trustless escrow, composability with other on-chain protocols, censorship resistance, global unblocked payments, transparent rules.]

## Success metrics
- Acquisition: how users find it.
- Activation: what "first successful use" looks like.
- Retention: how we know it's working 90 days in.
- Revenue (if any): who pays what.

## Non-goals
[What we're NOT building. More important than the goals for keeping scope real.]

## Risks
- User risk: [what would make users stop using it?]
- Economic risk: [what breaks the incentives?]
- Technical risk: [what's the biggest unknown?]
- Regulatory risk: [securities, KYC, geofenced?]

## Decisions needed
- [Each open architectural decision, with a recommended answer and deadline.]

## Out of scope (this version)
- [Features we've discussed but aren't shipping.]
```

Keep it under 2 pages. Longer briefs get ignored; shorter briefs hide gaps.

## Questions to ask (and expect gaps in the answers)

### About the user

- Does this user currently own a wallet? Which one?
- How much crypto have they handled before?
- On which chain? Are they willing to use a different one?
- Mobile or desktop? Bridge or native? Light client or full?

### About the economics

- Who pays gas — the user, us, someone else?
- What funds the platform — fees on transactions, subscription, token emission, nothing?
- How does the platform survive a bear market?

### About the trust model

- What value is at stake on-chain? How much per user? Across all users?
- What would an attacker gain by breaking the system? What's the worst-case payout for an attack?
- Which roles are centralized (admin, deployer, upgrade authority)? Is that acceptable?
- What can the team do to user funds? What can't we?

### About the data

- What data is the dApp writing to chain? How often? How much per transaction?
- What data is the dApp reading from chain? How fast? Historically how far back?
- What data lives off-chain? Who operates that storage?

### About the system

- How do users recover from a lost wallet, a failed transaction, a wrong network?
- What happens when the RPC provider goes down?
- What happens when a contract upgrade goes wrong?
- How do we turn it off in an emergency?

Gaps in the answers are where architecture risk hides. Surface them in the "Decisions needed" section.

## Common brief failures

### Brief is a list of features

```
❌ "The platform will have: minting, staking, governance, lending, a marketplace, NFTs, a DAO..."
```

Six products in one brief = one unshippable product. Pick one core loop; make it great; add the others later only if the core works.

### Brief is "will use blockchain"

```
❌ "This will be a decentralized <something> using smart contracts."
```

Not a problem statement. What does the user actually do? Why do they care that it's decentralized?

### Brief assumes the user thinks like the builder

```
❌ "Users will stake tokens to earn yield from protocol fees distributed based on a Curve-style gauge..."
```

If the user has no idea what a gauge is, the brief is written for the builder, not the user. Rewrite in language a normal human uses.

### No economic model

"How do we make money / sustain this?" — if the answer is "figure out later," architecture will suffer. Every contract decision has economic consequences; you need at least a rough model.

### No non-goals

Everything feels in scope. Midway through, scope creep will take the project down. Be explicit about what you're NOT doing.

## Iteration patterns

- **First pass is wrong.** Expect three iterations before the brief stabilizes.
- **Run the brief by a non-builder.** If your non-technical friend can't explain the dApp back to you after reading the brief, it's too complex.
- **Run the brief by a skeptic.** Someone who'll ask "why blockchain?" and "why you?" — not to kill it, but to stress-test.
- **Make the brief live.** Commit it to the repo as `docs/spec.md`. Update as decisions get made. It becomes the reference point when the team disagrees on scope.

## When you can't write a good brief

Sometimes the idea isn't ready for architecture. Signs:

- Three attempts to state the problem in one sentence all fail.
- Target user shifts between drafts ("maybe DAOs, maybe creators, maybe game studios").
- Economic model keeps hand-waving at "token will accrue value."
- Similar products exist and the brief doesn't explain what's different.

Don't force architecture in this case. Do user research, build a prototype, iterate on the brief. Architecting in a vacuum produces beautiful plans for wrong products.

## The brief is the north star

Once the brief is solid, it becomes the tie-breaker for every architecture decision: "does this choice serve the brief?" If yes, proceed. If no, cut.

Decisions made without anchoring to the brief tend to drift. Team arguments that don't reference the brief tend to be about ego, not architecture.
