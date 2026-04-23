# Skills

Reusable how-to skills an agent loads on demand to perform a specific task well.

Each skill lives in its own folder with a `SKILL.md` (concise, action-oriented) and an optional `references/` folder for long-form supporting docs.

## Available skills

| Skill | Purpose |
|-------|---------|
| [agent-skill-creator](./agent-skill-creator/SKILL.md) | Meta-skill — authors new skills for this repo with consistent format, frontmatter, and references. |
| [ngrx-feature-scaffold](./ngrx-feature-scaffold/SKILL.md) | Scaffold a complete NgRx feature (actions, reducer, effects, selectors, facade, tests) using modern Angular patterns. |
| [reown-appkit-web3](./reown-appkit-web3/SKILL.md) | Integrate `@reown/appkit` multi-chain wallet connections (EVM via wagmi, Solana, Bitcoin) — init, state, signing, security. |
| [wagmi-contract-interaction](./wagmi-contract-interaction/SKILL.md) | Read, write, and watch EVM smart contracts with wagmi v2 — simulate → write → wait, batched reads, event subscriptions, error handling. |

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
