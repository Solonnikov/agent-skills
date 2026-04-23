# On-chain randomness

Solana programs have three realistic options for randomness. Know the tradeoffs before picking.

## Option 1: SlotHashes sysvar (most common)

Every slot produces a blockhash. The `SlotHashes` sysvar stores the most recent 512 blockhashes. You can hash those into a pseudo-random value.

### Pros
- No extra dependencies.
- Cheap (one sysvar read + a hash).
- Provably-fair if users can verify after the fact.

### Cons
- Validators can see what hash they're about to produce and can — in edge cases — withhold or reorder to bias the outcome.
- For small, low-stakes randomness (UI dice, game of chance with modest bets) this is fine. For anything financially significant, use VRF.

### Pattern

```rust
use anchor_lang::solana_program::sysvar::slot_hashes::{self, SlotHashes};
use anchor_lang::solana_program::keccak;

#[derive(Accounts)]
pub struct RollDice<'info> {
    // ... game accounts ...

    /// CHECK: SlotHashes sysvar is pinned by the address constraint below.
    #[account(address = slot_hashes::id())]
    pub slot_hashes: UncheckedAccount<'info>,
}

pub fn handler(ctx: Context<RollDice>, nonce: u64) -> Result<()> {
    let sh = ctx.accounts.slot_hashes.to_account_info();
    let data = sh.try_borrow_data()?;

    // SlotHashes layout: [len: u64 LE][ (slot, hash) x len ]
    // The most recent hash starts at offset 8 + 8 (after len and first slot value).
    let hash_bytes = &data[16..48];  // 32-byte hash

    // Mix with any caller-supplied nonce + user pubkey for per-player variance.
    let entropy = keccak::hashv(&[
        hash_bytes,
        &nonce.to_le_bytes(),
        ctx.accounts.player.key().as_ref(),
    ]);

    // Use first 8 bytes as a u64.
    let value = u64::from_le_bytes(entropy.0[0..8].try_into().unwrap());
    let roll = (value % 6) + 1;

    // ... use roll ...
    Ok(())
}
```

Key points:
- Pin the sysvar with `address = slot_hashes::id()` — otherwise anyone can pass a fake account.
- Mix in the player's pubkey and a caller-supplied nonce so two identical-slot calls don't produce identical results.
- Don't use ONLY `Clock::get()?.unix_timestamp` or the slot number — those are too predictable.

## Option 2: Switchboard VRF

True on-chain randomness via an oracle network. The program requests randomness, the oracle signs and returns a proof, your program verifies the proof and consumes the random value.

### Pros
- Cryptographically verifiable, not biasable by validators.
- Audit-grade for financial products.

### Cons
- Extra CPIs and account setup.
- Costs SOL per request (oracle fee).
- Two-transaction flow: request → callback.

Use when the stakes are high enough that VRF fees are negligible compared to the cost of manipulation.

See Switchboard's VRF docs — the pattern is well-documented and not something to hand-roll.

## Option 3: Commit-reveal

Two-transaction pattern. User commits a hash of `(secret, nonce)` in one transaction; program commits the result of `blockhash * user_secret` in a second transaction after enough blocks have passed that the blockhash is immutable.

### Pros
- No oracle dependency.
- Unbiasable if blockhash distance is enforced.

### Cons
- Two transactions = worse UX.
- User must return to complete reveal, or you need an off-chain keeper.
- More complex to audit.

Appropriate for turn-based games where the two-step flow fits the game model anyway. Skip for fast-paced interactions.

## Anti-patterns

```rust
// ❌ Predictable — anyone can compute the same value.
let seed = Clock::get()?.unix_timestamp;

// ❌ Predictable and biasable — the slot number is visible to the caller.
let seed = Clock::get()?.slot;

// ❌ Predictable — the user picks the nonce.
let seed = u64::from_le_bytes(nonce.to_le_bytes());

// ❌ No sysvar pinning — attacker passes a fake "slot_hashes" account.
pub slot_hashes: UncheckedAccount<'info>,  // missing address constraint

// ❌ Using only the stored state — doesn't change between calls.
let seed = ctx.accounts.casino.nonce;
```

Anywhere the user or caller can predict or influence the seed, they can game the outcome.

## Rule of thumb

| Stakes | Use |
|--------|-----|
| Non-financial (UI flavor, free games, cosmetics) | SlotHashes + mixing |
| Small-value games (caps in the tens of dollars) | SlotHashes + mixing with published odds |
| Material financial outcomes | Switchboard VRF (or another verifiable VRF) |
| Provably-fair games where UX tolerates two txs | Commit-reveal |
