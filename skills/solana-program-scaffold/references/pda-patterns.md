# PDA patterns

Program-derived addresses (PDAs) are deterministic, program-owned addresses. Get the seed design right up front — they drive your whole account model.

## The three most common shapes

### 1. Singleton

One account for the whole program — global config, factory state, fee settings.

```rust
// state.rs
#[account]
pub struct FactoryState {
    pub owner: Pubkey,
    pub fee_bps: u16,
    pub count: u64,
    pub bump: u8,
}

impl FactoryState {
    pub const SEED: &'static [u8] = b"factory";
    pub const SIZE: usize = 32 + 2 + 8 + 1;  // matches struct fields
}
```

```rust
// instructions/init_factory.rs
#[derive(Accounts)]
pub struct InitFactory<'info> {
    #[account(
        init,
        payer = payer,
        space = 8 + FactoryState::SIZE,
        seeds = [FactoryState::SEED],
        bump,
    )]
    pub factory: Account<'info, FactoryState>,
    // ...
}
```

Derive from TypeScript:

```ts
const [factoryPda] = PublicKey.findProgramAddressSync(
  [Buffer.from('factory')],
  program.programId,
);
```

### 2. Indexed (counter-based)

Many accounts owned by the program, created in sequence, never deleted. Factory tracks the counter; each item's seed includes its index.

```rust
// state.rs
#[account]
pub struct Casino {
    pub owner: Pubkey,
    pub index: u64,
    pub bump: u8,
    // ...
}

impl Casino {
    pub const SEED: &'static [u8] = b"casino";
}
```

```rust
// instructions/create_casino.rs
#[derive(Accounts)]
pub struct CreateCasino<'info> {
    #[account(mut, seeds = [FactoryState::SEED], bump = factory.bump)]
    pub factory: Account<'info, FactoryState>,

    #[account(
        init,
        payer = payer,
        space = 8 + Casino::SIZE,
        seeds = [Casino::SEED, factory.count.to_le_bytes().as_ref()],
        bump,
    )]
    pub casino: Account<'info, Casino>,

    #[account(mut)]
    pub payer: Signer<'info>,
    pub system_program: Program<'info, System>,
}

pub fn handler(ctx: Context<CreateCasino>) -> Result<()> {
    let factory = &mut ctx.accounts.factory;
    let casino = &mut ctx.accounts.casino;

    casino.owner = ctx.accounts.payer.key();
    casino.index = factory.count;
    casino.bump = ctx.bumps.casino;

    factory.count = factory.count.checked_add(1).ok_or(MyError::Overflow)?;
    Ok(())
}
```

Derive from TypeScript with the counter:

```ts
const index = new BN(42);
const [casinoPda] = PublicKey.findProgramAddressSync(
  [Buffer.from('casino'), index.toArrayLike(Buffer, 'le', 8)],
  program.programId,
);
```

The `to_le_bytes()` / `toArrayLike('le', 8)` symmetry matters — get it wrong on either side and the PDA doesn't match.

### 3. Per-user

One account per user — e.g. a per-wallet profile, a position, a vault.

```rust
#[account(
    init,
    payer = user,
    space = 8 + UserAccount::SIZE,
    seeds = [b"user", user.key().as_ref()],
    bump,
)]
pub user_account: Account<'info, UserAccount>,
```

```ts
const [userPda] = PublicKey.findProgramAddressSync(
  [Buffer.from('user'), wallet.publicKey.toBuffer()],
  program.programId,
);
```

## Vault PDAs for SPL tokens

When a program holds SPL tokens on behalf of an account, separate the **state PDA** from the **token account PDA**. The state PDA owns business data; the token account PDA holds tokens.

```rust
// instructions/create_casino.rs (SPL variant)
#[derive(Accounts)]
pub struct CreateCasinoSpl<'info> {
    #[account(mut, seeds = [FactoryState::SEED], bump = factory.bump)]
    pub factory: Account<'info, FactoryState>,

    #[account(
        init,
        payer = payer,
        space = 8 + Casino::SIZE,
        seeds = [Casino::SEED, factory.count.to_le_bytes().as_ref()],
        bump,
    )]
    pub casino: Account<'info, Casino>,

    #[account(
        init,
        payer = payer,
        seeds = [b"vault", casino.key().as_ref()],
        bump,
        token::mint = mint,
        token::authority = vault,       // vault is its own authority
    )]
    pub vault: Account<'info, TokenAccount>,

    pub mint: Account<'info, Mint>,

    #[account(mut)]
    pub payer: Signer<'info>,

    pub token_program: Program<'info, Token>,
    pub system_program: Program<'info, System>,
    pub rent: Sysvar<'info, Rent>,
}
```

The vault's authority is the vault itself — the program signs CPIs on its behalf using the bump.

## Storing bumps

**Always store the bump** on the account's state:

```rust
#[account]
pub struct Casino {
    pub owner: Pubkey,
    pub bump: u8,         // store the canonical bump
    // ...
}
```

**Always re-derive with the stored bump** in subsequent instructions:

```rust
#[account(
    mut,
    seeds = [Casino::SEED, casino.index.to_le_bytes().as_ref()],
    bump = casino.bump,   // NOT just `bump` — use the stored one
)]
pub casino: Account<'info, Casino>,
```

Without storing, Anchor has to try all 255 candidate bumps to find the canonical one on every access — up to ~3,000 CU extra per instruction.

## Seed size limits

Each seed is capped at 32 bytes, and you can have up to 16 seeds. For most use cases you'll use 1–3 seeds. If you're packing more than that, reconsider — there's usually a cleaner account hierarchy.

## What NOT to use as a seed

- User-provided strings without bounds (DoS risk — long seeds consume compute).
- Timestamps (not deterministic across slots).
- Results of `rand` or other non-deterministic values.
- External account keys you don't control (the caller can pick any "external" account — seed becomes attacker-controlled).
