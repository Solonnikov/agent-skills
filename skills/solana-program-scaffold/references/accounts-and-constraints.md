# Accounts and constraints

`#[derive(Accounts)]` is Anchor's primary validation surface. Every check you'd otherwise do in the handler body belongs here.

## Why constraints, not runtime `if`s

```rust
// ❌ Runtime check in handler
pub fn handler(ctx: Context<PlaceBet>) -> Result<()> {
    if ctx.accounts.casino.owner != ctx.accounts.owner.key() {
        return err!(MyError::NotCasinoOwner);
    }
    if ctx.accounts.casino.closed {
        return err!(MyError::CasinoClosed);
    }
    // ...
}

// ✅ Constraints in account struct
#[derive(Accounts)]
pub struct PlaceBet<'info> {
    #[account(
        mut,
        seeds = [Casino::SEED, casino.index.to_le_bytes().as_ref()],
        bump = casino.bump,
        constraint = casino.owner == owner.key() @ MyError::NotCasinoOwner,
        constraint = !casino.closed              @ MyError::CasinoClosed,
    )]
    pub casino: Account<'info, Casino>,
    pub owner: Signer<'info>,
    // ...
}

pub fn handler(ctx: Context<PlaceBet>) -> Result<()> {
    // Handler only runs if every constraint passed.
    // ...
}
```

Benefits:
- Validation happens before the handler runs — no partial state changes.
- Constraints are part of the IDL — clients can inspect them.
- Attributed errors make debugging dramatically easier than `ConstraintRaw`.

## The constraint attributes

### `seeds` + `bump`

```rust
#[account(
    seeds = [b"casino", casino.index.to_le_bytes().as_ref()],
    bump = casino.bump,
)]
```

Re-derives the PDA and verifies the passed account matches. Always use the stored `bump` (see pda-patterns.md).

### `has_one`

```rust
#[account(has_one = owner @ MyError::NotCasinoOwner)]
pub casino: Account<'info, Casino>,
pub owner: Signer<'info>,
```

Short form for `constraint = casino.owner == owner.key() @ ErrorCode`. Use when the struct field is literally named after the account.

### `constraint`

General-purpose boolean:

```rust
constraint = casino.mint == Pubkey::default() @ MyError::WrongMintType,
constraint = amount >= casino.min_bet         @ MyError::BetTooSmall,
constraint = amount <= casino.max_bet         @ MyError::BetTooLarge,
```

### `init`, `init_if_needed`, `close`

```rust
#[account(
    init,
    payer = payer,
    space = 8 + Casino::SIZE,
    seeds = [Casino::SEED, factory.count.to_le_bytes().as_ref()],
    bump,
)]
pub casino: Account<'info, Casino>,
```

- `init` — creates the account. Requires `payer` to fund the rent, and `system_program` in the accounts.
- `init_if_needed` — only initializes if the account doesn't exist. Dangerous — allows a user to skip initialization by providing a pre-existing account. Gate it behind strict checks.
- `close = recipient` — closes the account and sends its lamports to `recipient`. State is zeroed.

### `mut`

```rust
#[account(mut)]
pub user_account: Account<'info, UserAccount>,
```

Marks the account as mutable — required for any write. Missing `mut` on a write silently fails to persist changes.

## Account type choices

| Type | When |
|------|------|
| `Account<'info, T>` | Default — Anchor-managed account with a discriminator. |
| `Signer<'info>` | Must have signed the transaction. |
| `UncheckedAccount<'info>` | No validation; raw account ref. Only with `/// CHECK:` comment explaining why. |
| `SystemAccount<'info>` | A plain SOL account (no data). |
| `Program<'info, T>` | A specific program (Token, System, Associated Token, etc). |
| `Sysvar<'info, T>` | A sysvar account (Rent, Clock, SlotHashes). |

## Ownership + state validation pattern

Combine checks:

```rust
#[derive(Accounts)]
pub struct UpdateCasino<'info> {
    #[account(
        mut,
        seeds = [Casino::SEED, casino.index.to_le_bytes().as_ref()],
        bump = casino.bump,
        has_one = owner @ MyError::NotCasinoOwner,
        constraint = !casino.closed @ MyError::CasinoClosed,
    )]
    pub casino: Account<'info, Casino>,

    pub owner: Signer<'info>,
}
```

Every invariant checked. Every failure mode has its own attributed error. The handler can focus on the state change.

## `UncheckedAccount` — use sparingly

Sometimes you need an account whose type Anchor can't express — another program's account, or something you're only passing through. Use `UncheckedAccount`, but **always with a `/// CHECK:` doc comment** explaining why it's safe:

```rust
/// CHECK: This is the SlotHashes sysvar; we read it directly via AccountInfo.
#[account(address = solana_program::sysvar::slot_hashes::id())]
pub slot_hashes: UncheckedAccount<'info>,
```

The `address = ...` constraint verifies the caller didn't pass a different account. Without it, `UncheckedAccount` is a free-for-all.

## Space calculation

```rust
impl Casino {
    pub const SIZE: usize = 32   // owner: Pubkey
        + 32                     // mint: Pubkey
        + 8                      // index: u64
        + 2                      // fee_bps: u16
        + 8                      // bankroll: u64
        + 1                      // closed: bool
        + 1;                     // bump: u8
}

// In #[derive(Accounts)]:
#[account(init, payer = payer, space = 8 + Casino::SIZE, ...)]
```

`8 + SIZE` — the 8-byte Anchor discriminator sits at the start of every account. Forget it and account data gets misaligned.

For `String` or `Vec` fields, include the 4-byte length prefix and the max content size: `4 + MAX_LEN`.
