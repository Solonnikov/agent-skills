# SOL vs SPL token flows

If your program accepts value, it needs both a SOL path and an SPL path. Keep them parallel — don't try to unify them in a single polymorphic instruction.

## Why parallel, not unified

A program that accepts SOL transfers lamports via `system_program::transfer`. A program that accepts SPL tokens transfers via `token::transfer` through a CPI. The account structures are different:

- SOL: from a `SystemAccount` to a program-owned account.
- SPL: from a `TokenAccount` (user) to a `TokenAccount` (vault PDA) with a `Mint`, `TokenProgram`, etc.

A "unified" instruction that branches on `if mint == Pubkey::default()` has to make many accounts optional, which Anchor doesn't express well, which makes the IDL confusing, which means clients get harder to write. Parallel instructions are longer in absolute lines but easier to reason about, test, and audit.

## The pattern

```rust
// instructions/place_bet.rs (both variants in one file is fine)

#[derive(Accounts)]
pub struct PlaceBetSol<'info> {
    #[account(
        mut,
        seeds = [Casino::SEED, casino.index.to_le_bytes().as_ref()],
        bump = casino.bump,
        constraint = casino.mint == Pubkey::default() @ MyError::WrongMintType,
    )]
    pub casino: Account<'info, Casino>,

    #[account(mut)]
    pub player: Signer<'info>,

    /// CHECK: SlotHashes sysvar for randomness.
    #[account(address = solana_program::sysvar::slot_hashes::id())]
    pub slot_hashes: UncheckedAccount<'info>,

    pub system_program: Program<'info, System>,
}

pub fn handler_sol(ctx: Context<PlaceBetSol>, amount: u64) -> Result<()> {
    // Transfer lamports from player to casino PDA.
    let ix = system_instruction::transfer(
        &ctx.accounts.player.key(),
        &ctx.accounts.casino.key(),
        amount,
    );
    invoke(
        &ix,
        &[
            ctx.accounts.player.to_account_info(),
            ctx.accounts.casino.to_account_info(),
            ctx.accounts.system_program.to_account_info(),
        ],
    )?;

    // ...game logic, payout, events...
    Ok(())
}

#[derive(Accounts)]
pub struct PlaceBetSpl<'info> {
    #[account(
        mut,
        seeds = [Casino::SEED, casino.index.to_le_bytes().as_ref()],
        bump = casino.bump,
        constraint = casino.mint == mint.key() @ MyError::WrongMintType,
    )]
    pub casino: Account<'info, Casino>,

    pub mint: Account<'info, Mint>,

    #[account(
        mut,
        seeds = [b"vault", casino.key().as_ref()],
        bump,
        token::mint = mint,
    )]
    pub vault: Account<'info, TokenAccount>,

    #[account(
        mut,
        token::mint = mint,
        token::authority = player,
    )]
    pub player_token: Account<'info, TokenAccount>,

    #[account(mut)]
    pub player: Signer<'info>,

    /// CHECK: SlotHashes sysvar.
    #[account(address = solana_program::sysvar::slot_hashes::id())]
    pub slot_hashes: UncheckedAccount<'info>,

    pub token_program: Program<'info, Token>,
}

pub fn handler_spl(ctx: Context<PlaceBetSpl>, amount: u64) -> Result<()> {
    // CPI: transfer from player to vault.
    let cpi = CpiContext::new(
        ctx.accounts.token_program.to_account_info(),
        Transfer {
            from: ctx.accounts.player_token.to_account_info(),
            to: ctx.accounts.vault.to_account_info(),
            authority: ctx.accounts.player.to_account_info(),
        },
    );
    token::transfer(cpi, amount)?;

    // ...game logic...
    Ok(())
}
```

## Mint discrimination on the state account

Use a single `mint: Pubkey` field on the state account to track what currency it's configured for:

```rust
#[account]
pub struct Casino {
    pub mint: Pubkey,     // Pubkey::default() means SOL
    // ...
}
```

Then each instruction constrains `casino.mint` appropriately:

- `PlaceBetSol`: `constraint = casino.mint == Pubkey::default() @ MyError::WrongMintType`
- `PlaceBetSpl`: `constraint = casino.mint == mint.key() @ MyError::WrongMintType`

This prevents cross-currency attacks — a player can't call the SOL variant on an SPL casino.

## Payout: program-owned accounts as signers

For payouts from an SPL vault, the vault itself is the authority and needs to sign via its seeds:

```rust
pub fn payout_spl(ctx: Context<PayoutSpl>, amount: u64) -> Result<()> {
    let casino_key = ctx.accounts.casino.key();
    let bump = ctx.bumps.vault;
    let seeds: &[&[&[u8]]] = &[&[b"vault", casino_key.as_ref(), &[bump]]];

    let cpi = CpiContext::new_with_signer(
        ctx.accounts.token_program.to_account_info(),
        Transfer {
            from: ctx.accounts.vault.to_account_info(),
            to: ctx.accounts.player_token.to_account_info(),
            authority: ctx.accounts.vault.to_account_info(),
        },
        seeds,
    );
    token::transfer(cpi, amount)?;
    Ok(())
}
```

For SOL payouts, directly mutate lamports on the PDA:

```rust
**ctx.accounts.casino.to_account_info().try_borrow_mut_lamports()? -= amount;
**ctx.accounts.player.to_account_info().try_borrow_mut_lamports()? += amount;
```

Only the program can mutate a PDA's lamports (because it owns them). Make sure you don't underflow below the rent-exempt minimum.

## Rent-exempt minimum

PDAs need to hold enough lamports to be rent-exempt. If a SOL casino's bankroll drops below the rent floor, the account can be purged. Track the rent floor on the state:

```rust
pub fn close_casino(ctx: Context<CloseCasino>) -> Result<()> {
    let rent = Rent::get()?;
    let minimum = rent.minimum_balance(ctx.accounts.casino.to_account_info().data_len());
    let surplus = ctx.accounts.casino.to_account_info().lamports()
        .saturating_sub(minimum);
    // Refund surplus to owner, leave minimum in place.
    **ctx.accounts.casino.to_account_info().try_borrow_mut_lamports()? = minimum;
    **ctx.accounts.owner.to_account_info().try_borrow_mut_lamports()? += surplus;
    Ok(())
}
```
