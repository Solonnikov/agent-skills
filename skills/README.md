# Skills

Reusable how-to skills an agent loads on demand to perform a specific task well.

Each skill lives in its own folder with a `SKILL.md` (concise, action-oriented) and an optional `references/` folder for long-form supporting docs.

## Available skills

### Meta

| Skill | Purpose |
|-------|---------|
| [agent-skill-creator](./agent-skill-creator/SKILL.md) | Authors new skills for this repo with consistent format, frontmatter, and references. |

### Frontend / Angular

| Skill | Purpose |
|-------|---------|
| [ngrx-feature-scaffold](./ngrx-feature-scaffold/SKILL.md) | Scaffold a complete NgRx feature (actions, reducer, effects, selectors, facade, tests) using modern Angular patterns. |

### Web3 — EVM

| Skill | Purpose |
|-------|---------|
| [evm-contract-scaffold](./evm-contract-scaffold/SKILL.md) | Bootstrap a Solidity project — Foundry-first with Hardhat alternative, OpenZeppelin patterns, testing, deployment. |
| [hardhat-etherscan-verification](./hardhat-etherscan-verification/SKILL.md) | Verify deployed contracts — plugin path for the common case, manual V2 API fallback for edge cases. |
| [reown-appkit-web3](./reown-appkit-web3/SKILL.md) | Integrate `@reown/appkit` multi-chain wallet connections (EVM via wagmi, Solana, Bitcoin). |
| [wagmi-contract-interaction](./wagmi-contract-interaction/SKILL.md) | Read, write, and watch EVM smart contracts with wagmi v2 — simulate/write/wait, batched reads, events, error handling. |

### Web3 — Solana

| Skill | Purpose |
|-------|---------|
| [solana-program-scaffold](./solana-program-scaffold/SKILL.md) | Bootstrap an Anchor program — PDA patterns, dual SOL/SPL instruction variants, constraint-driven validation, on-chain randomness, testing, deployment. |

## Format

Every `SKILL.md` has YAML frontmatter:

```markdown
---
name: kebab-case-skill-name
description: <what it does>. Use when <trigger scenarios>.
---
```

Keep `SKILL.md` tight and operational (aim for <80 lines). Put depth — templates, checklists, cheatsheets — in `references/*.md` and link to them by description, not file name.

Full format rules: see [agent-skill-creator](./agent-skill-creator/SKILL.md).
