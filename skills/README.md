# Skills

Reusable skills an agent can load on demand to perform a specific task well.

Each skill lives in its own folder with a `SKILL.md` (concise, action-oriented) and an optional `references/` folder for long-form supporting docs.

## Available skills

| Skill | Purpose |
|-------|---------|
| [ngrx-feature-scaffold](./ngrx-feature-scaffold/SKILL.md) | Scaffold a complete NgRx feature (actions, reducer, effects, selectors, facade, tests) using modern Angular + NgRx patterns. |
| [reown-appkit-web3](./reown-appkit-web3/SKILL.md) | Integrate `@reown/appkit` multi-chain wallet connections (EVM via wagmi, Solana, Bitcoin) into a web app. |

## Format conventions

Every `SKILL.md` has YAML frontmatter:

```markdown
---
name: kebab-case-skill-name
description: <what it does>. Use when <trigger scenarios>.
---
```

Keep `SKILL.md` tight and operational. Put depth — examples, templates, checklists — in `references/*.md` and link to them by description, not file name.
