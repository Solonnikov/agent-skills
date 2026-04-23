# Frontmatter rules

Every `SKILL.md` starts with YAML frontmatter. Two fields are required; a third is optional.

## Required

```yaml
---
name: <kebab-case-skill-name>
description: <what it does>. Use when <trigger scenarios>.
---
```

### `name`
- Kebab-case, lowercase.
- Exactly matches the folder name: `skills/<name>/SKILL.md`.
- Short and specific. `wagmi-contract-interaction`, not `web3-stuff`.
- No version suffix, no domain prefix (the folder structure does that).

### `description`
One sentence, two halves:

1. **What it does.** Starts with an action verb — "Scaffolds", "Integrates", "Audits", "Generates". Present tense.
2. **When to use.** Explicit trigger scenarios separated by commas — the phrases that would appear in a real user request.

Pattern: `<action verb phrase>. Use when <comma-separated trigger scenarios>.`

Good examples:

```
description: Scaffolds a complete NgRx feature (actions, reducer, effects, selectors, facade, tests) using modern Angular patterns. Use when adding a new feature slice to an Angular + NgRx app, standardizing existing ad-hoc state code, or bootstrapping state for a new library in an Nx monorepo.
```

```
description: Integrates @reown/appkit multi-chain wallet connections (EVM via wagmi, Solana, Bitcoin). Use when adding wallet connect support to a new app, extending an existing app to a new chain family, or standardizing wallet state management.
```

Bad examples:

```
description: Helps with NgRx stuff.
# Too vague — no action, no trigger.

description: A comprehensive, state-of-the-art skill for authoring production-grade NgRx features using the latest best practices.
# Marketing copy, no trigger.

description: Scaffolds NgRx features. Use when needed.
# "When needed" doesn't describe trigger scenarios.
```

## Optional

- `tools` — comma-separated list of tools the skill expects to use (`Read, Write, Grep`). Only add if you want to document a tool scope; the hosting agent decides what's actually available.

## What is NOT frontmatter

- Author name, date, version — release tags carry version, git log carries author and date.
- Tags or categories — folder structure is the taxonomy.
- Long descriptions — anything that doesn't fit one sentence belongs in the body.
