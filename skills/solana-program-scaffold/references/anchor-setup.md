# Anchor workspace setup

## Install

```bash
# Solana CLI
sh -c "$(curl -sSfL https://release.solana.com/stable/install)"

# Anchor via avm
cargo install --git https://github.com/coral-xyz/anchor avm --force
avm install 0.31.1
avm use 0.31.1

# Init a workspace
anchor init my-program
cd my-program
```

## Workspace layout

```
my-program/
├── Anchor.toml
├── Cargo.toml                  # workspace Cargo manifest
├── programs/
│   └── my-program/
│       ├── Cargo.toml
│       └── src/
│           ├── lib.rs          # #[program] dispatch
│           ├── state.rs        # #[account] structs
│           ├── errors.rs       # #[error_code] enum
│           ├── constants.rs    # SEED constants, decimals, limits
│           └── instructions/
│               ├── mod.rs
│               ├── init.rs
│               └── do_thing.rs
├── tests/
│   └── my-program.ts           # Anchor client tests
└── migrations/
    └── deploy.ts
```

## `programs/my-program/Cargo.toml`

```toml
[package]
name = "my-program"
version = "0.1.0"
edition = "2021"

[lib]
crate-type = ["cdylib", "lib"]
name = "my_program"

[features]
default = []
no-entrypoint = []          # when another program depends on this one (CPI)
cpi = ["no-entrypoint"]
idl-build = ["anchor-lang/idl-build"]

[dependencies]
anchor-lang = "0.31.1"
anchor-spl  = "0.31.1"       # only if you handle SPL tokens
```

## `Anchor.toml`

```toml
[toolchain]
anchor_version = "0.31.1"

[features]
seeds = false
skip-lint = false

[programs.localnet]
my_program = "<PROGRAM_ID>"

[programs.devnet]
my_program = "<PROGRAM_ID>"

[programs.mainnet]
my_program = "<PROGRAM_ID>"

[registry]
url = "https://api.apr.dev"

[provider]
cluster = "localnet"
wallet = "~/.config/solana/id.json"

[scripts]
test = "yarn run ts-mocha -p ./tsconfig.json -t 1000000 tests/**/*.ts"
```

Program IDs per cluster: you generate one with `solana-keygen new -o target/deploy/my_program-keypair.json`, then `solana address -k target/deploy/my_program-keypair.json` — paste the result into `declare_id!()` and `Anchor.toml`.

## `src/lib.rs` — dispatch table

```rust
use anchor_lang::prelude::*;

pub mod constants;
pub mod errors;
pub mod instructions;
pub mod state;

use instructions::*;

declare_id!("<YOUR_PROGRAM_ID>");

#[program]
pub mod my_program {
    use super::*;

    pub fn initialize(ctx: Context<Initialize>, args: InitializeArgs) -> Result<()> {
        instructions::initialize::handler(ctx, args)
    }

    pub fn do_thing(ctx: Context<DoThing>, amount: u64) -> Result<()> {
        instructions::do_thing::handler(ctx, amount)
    }
}
```

Keep `lib.rs` as pure dispatch. Every handler lives in its instruction module.

## `src/instructions/mod.rs`

```rust
pub mod initialize;
pub mod do_thing;

pub use initialize::*;
pub use do_thing::*;
```

## `src/instructions/initialize.rs`

```rust
use anchor_lang::prelude::*;
use crate::state::MyAccount;
use crate::errors::MyError;

#[derive(AnchorSerialize, AnchorDeserialize, Clone)]
pub struct InitializeArgs {
    pub fee_bps: u16,
}

#[derive(Accounts)]
pub struct Initialize<'info> {
    #[account(
        init,
        payer = payer,
        space = 8 + MyAccount::SIZE,
        seeds = [b"my_account"],
        bump,
    )]
    pub my_account: Account<'info, MyAccount>,

    #[account(mut)]
    pub payer: Signer<'info>,

    pub system_program: Program<'info, System>,
}

pub fn handler(ctx: Context<Initialize>, args: InitializeArgs) -> Result<()> {
    require!(args.fee_bps <= 10_000, MyError::InvalidFee);

    let account = &mut ctx.accounts.my_account;
    account.owner = ctx.accounts.payer.key();
    account.fee_bps = args.fee_bps;
    account.bump = ctx.bumps.my_account;
    Ok(())
}
```

## Build and test

```bash
anchor build          # compiles and generates IDL
anchor test           # starts a local validator, deploys, runs tests
anchor deploy --provider.cluster devnet
```

First `anchor build` is slow (~1 min). Incremental builds are fast.
