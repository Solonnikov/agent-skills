# Skills

Reusable how-to skills an agent loads on demand to perform a specific task well.

Each skill lives in its own folder with a `SKILL.md` (concise, action-oriented) and an optional `references/` folder for long-form supporting docs.

## Available skills

### Meta

| Skill | Purpose |
|-------|---------|
| [agent-skill-creator](./agent-skill-creator/SKILL.md) | Authors new skills for this repo with consistent format, frontmatter, and references. |

### Architect-style (design playbooks)

| Skill | Purpose |
|-------|---------|
| [dapp-architect](./dapp-architect/SKILL.md) | End-to-end dApp design — brief, trust boundaries, contract layer, client layer, indexing, off-chain services, deployment + ops. |

### Everyday dev

| Skill | Purpose |
|-------|---------|
| [git-workflow-recipes](./git-workflow-recipes/SKILL.md) | Recipes for undoing mistakes, safe rebasing, resolving conflicts, rescuing lost work, PR-friendly history cleanup. |
| [regex-cookbook](./regex-cookbook/SKILL.md) | Copy-ready regex patterns for the strings people match every day — plus building blocks, language differences, and debugging. |

### Writing, work & life

| Skill | Purpose |
|-------|---------|
| [writing-style-editor](./writing-style-editor/SKILL.md) | Tighten prose — cut fluff, vary sentence length, strengthen verbs, match a target voice. |
| [email-drafting](./email-drafting/SKILL.md) | Draft emails in the right tone and length — cold outreach, follow-up, apology, decline, difficult feedback. |
| [meeting-notes-structure](./meeting-notes-structure/SKILL.md) | Meeting notes that capture decisions and action items — templates for standups, 1-on-1s, retros, planning. |
| [resume-tailor](./resume-tailor/SKILL.md) | Tailor a résumé to a specific JD — parse the posting, rewrite bullets, quantify, pass ATS filters. |
| [content-repurposing](./content-repurposing/SKILL.md) | Turn one piece of content into multiple surfaces — blog → thread → LinkedIn → newsletter — matching each platform. |
| [research-brief-structure](./research-brief-structure/SKILL.md) | Research briefs that answer a question — sources, synthesis, recommendation, gaps, triggers to revisit. |

### AI / LLM engineering

| Skill | Purpose |
|-------|---------|
| [prompt-engineering-patterns](./prompt-engineering-patterns/SKILL.md) | Structure prompts for production LLM apps — roles, delimiters, chain-of-thought, few-shot, structured output, caching, evaluation. |

### Frontend / Angular

| Skill | Purpose |
|-------|---------|
| [ngrx-feature-scaffold](./ngrx-feature-scaffold/SKILL.md) | Scaffold a complete NgRx feature (actions, reducer, effects, selectors, facade, tests) using modern Angular patterns. |

### Backend / payments

| Skill | Purpose |
|-------|---------|
| [stripe-subscription-lifecycle](./stripe-subscription-lifecycle/SKILL.md) | Stripe subscriptions end-to-end — webhook-driven state sync, cancellation, tier downgrades, testing with the Stripe CLI. |

### Web / SEO

| Skill | Purpose |
|-------|---------|
| [technical-seo-checklist](./technical-seo-checklist/SKILL.md) | Audit and implement the technical SEO basics — metadata, structured data, crawlability, Core Web Vitals, international targeting. |

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
