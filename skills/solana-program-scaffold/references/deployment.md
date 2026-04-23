# Deployment and upgrade authority

The four-step flow: build → verify size → deploy → initialize. Everything after that is about authority control.

## Build and verify size

```bash
anchor build
ls -la target/deploy/
```

Two files appear:
- `my_program.so` — the program binary.
- `my_program-keypair.json` — the program ID keypair. **Back this up.** If you lose it, you lose upgrade authority (until you transfer it elsewhere).

Check the binary size:

```bash
du -b target/deploy/my_program.so
# Rule of thumb: <200 KB is comfortable, >300 KB costs real rent.
```

To shrink:

```bash
# In Cargo.toml:
[profile.release]
opt-level = "z"           # optimize for size
lto = true
codegen-units = 1
strip = true
```

`anchor build --release --no-idl` skips IDL emission if it bloats unexpectedly (rare).

Calculate rent for the binary:

```bash
solana rent $(du -b target/deploy/my_program.so | cut -f1)
# "Rent-exempt minimum: X.YZ SOL"
```

## Deploy to devnet

```bash
solana config set --url devnet
solana airdrop 5    # fund your deployer wallet (devnet only)
anchor deploy --provider.cluster devnet
```

Anchor writes the deployed program ID back into `Anchor.toml` automatically.

If the deploy fails partway through (it sometimes does on slow RPCs), resume:

```bash
solana program deploy --buffer <BUFFER_ADDRESS> target/deploy/my_program.so
```

## Deploy to mainnet

### Pre-flight

- [ ] `solana config get` — confirm cluster is mainnet-beta, wallet is the one you intend to use as deployer.
- [ ] Binary size acceptable. Rent calculated and available in the wallet.
- [ ] Program ID in `declare_id!()` matches `target/deploy/my_program-keypair.json`.
- [ ] `Anchor.toml` has the program ID under `[programs.mainnet]`.
- [ ] Tests pass against a mainnet-fork (LiteSVM supports this via RPC snapshot).
- [ ] Audit complete, if applicable.

### Deploy

```bash
solana config set --url mainnet-beta
anchor deploy --provider.cluster mainnet
```

### Initialize

Run your `initialize` instruction to set up factory / config accounts:

```ts
// scripts/init-mainnet.ts
import * as anchor from '@coral-xyz/anchor';
const provider = anchor.AnchorProvider.env();
anchor.setProvider(provider);
const program = anchor.workspace.MyProgram;

await program.methods
  .initFactory({ /* args */ })
  .accounts({ /* ... */ })
  .rpc();
```

```bash
anchor run init-mainnet
```

## Upgrade authority

By default, the wallet that deployed the program holds the **upgrade authority** — it can replace the program with a new version.

### Check current authority

```bash
solana program show <PROGRAM_ID>
```

### Transfer to a multisig / hardware wallet

For mainnet production, transfer authority away from the deployer EOA immediately after verifying the deploy:

```bash
solana program set-upgrade-authority <PROGRAM_ID> \
  --new-upgrade-authority <MULTISIG_OR_HARDWARE_WALLET_ADDRESS>
```

Squads (a Solana multisig) is the common choice. Losing the upgrade authority means you can never upgrade the program again — plan accordingly.

### Make immutable

When you're done upgrading forever:

```bash
solana program set-upgrade-authority <PROGRAM_ID> --final
```

Once final, the program is read-only forever. Irreversible — don't do this on a program you might need to patch.

## Upgrading

```bash
anchor build
anchor upgrade target/deploy/my_program.so --program-id <PROGRAM_ID>
```

Upgrade semantics:
- The program ID stays the same.
- Account data layouts must stay compatible (new versions cannot rearrange or shrink existing fields).
- Clients using the old IDL keep working for the instructions they already know about.

## Verify the deployed program

```bash
anchor verify <PROGRAM_ID> \
  --provider.cluster mainnet
```

This rebuilds your source and compares to the on-chain bytecode. Published on apr.dev so others can confirm the deployed program matches the commit hash.

## Rollback plan

Solana doesn't have a "rollback" concept — you can only upgrade forward. Your rollback is "deploy the previous version on top of the current one." Keep tagged git commits for every deployed version so you can check out and redeploy any prior state.

## Deploy log

Keep `deployments/<cluster>.md` (or `.json`) with every deploy:

- Program ID.
- Commit hash / git tag.
- Anchor + Solana CLI versions.
- Binary size.
- Deployer address + upgrade authority at time of deploy.
- Date.
- Any initialization commands run after deploy.

When someone asks "which version is running?", you look at this file, not at the chain.
